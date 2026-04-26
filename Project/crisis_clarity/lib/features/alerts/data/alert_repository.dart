import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../domain/alert_model.dart';

class AlertRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AlertModel>> getActiveAlerts(String ward) {
    // Try Firestore stream first
    final firestoreStream = _firestore.collection('alerts')
        .where('isActive', isEqualTo: true)
        .where('affectedZones', arrayContains: ward)
        .snapshots()
        .map((snapshot) {
          final alerts = snapshot.docs
              .map((doc) => AlertModel.fromFirestore(doc))
              .toList();
          alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return alerts;
        });

    // Fallback: Combine with an initial fetch from the backend API
    // This handles local mode where Firestore might be empty or unreachable
    return firestoreStream.handleError((e) {
      print('Firestore error (falling back to API): $e');
      return Stream.fromFuture(_fetchAlertsFromApi());
    }).asyncMap((alerts) async {
      if (alerts.isEmpty) {
        return await _fetchAlertsFromApi();
      }
      return alerts;
    });
  }

  Future<List<AlertModel>> _fetchAlertsFromApi() async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/active-alerts');
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> alertsData = data['alerts'];
        return alertsData.map((a) {
          // Map backend v2 fields to AlertModel
          return AlertModel(
            id: a['event_id'] ?? a['doc_id'] ?? DateTime.now().toString(),
            titleEn: a['title'] ?? '',
            titleHi: a['titleHi'] ?? '',
            titleMr: a['titleMr'] ?? '',
            descriptionEn: a['description'] ?? a['summary'] ?? '',
            descriptionHi: a['descriptionHi'] ?? '',
            descriptionMr: a['descriptionMr'] ?? '',
            simplifiedEn: a['ai_analysis']?['risk_summary'] ?? '',
            simplifiedHi: '',
            simplifiedMr: '',
            disasterType: a['disasterType'] ?? a['disaster_type'] ?? 'other',
            severity: a['severity'] ?? 'low',
            affectedZones: List<String>.from(a['affectedZones'] ?? []),
            postedBy: a['postedBy'] ?? 'CrisisClarity Engine',
            createdAt: a['createdAt'] != null ? DateTime.parse(a['createdAt']) : DateTime.now(),
            updatedAt: DateTime.now(),
            trustScore: a['trustScore'] ?? 50,
            trustStatus: a['trustStatus'] ?? 'partial',
          );
        }).toList();
      }
    } catch (e) {
      print('Error fetching alerts from API: $e');
    }
    return [];
  }

  Stream<List<Map<String, dynamic>>> getAlertUpdates(String alertId) {
    return _firestore.collection('alerts').doc(alertId).collection('updates')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<Map<String, String>>> getSafetyInstructions(String disasterType) async {
    final doc = await _firestore.collection('safetyInstructions').doc(disasterType).get();
    if (doc.exists && doc.data() != null) {
      final steps = doc.data()!['steps'] as List<dynamic>;
      return steps.map((s) => Map<String, String>.from(s)).toList();
    }
    return [];
  }

  Future<void> submitFeedback(String alertId, String userId, String response) async {
    final feedbackId = '${alertId}_$userId';
    final batch = _firestore.batch();

    // Feedback doc
    batch.set(_firestore.collection('feedback').doc(feedbackId), {
      'alertId': alertId,
      'userId': userId,
      'response': response,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment Alert Counter
    final counterField = response == 'understood' ? 'understood' : 'notUnderstood';
    batch.update(_firestore.collection('alerts').doc(alertId), {
      counterField: FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> likeAlert(String alertId) async {
    try {
      await _firestore.collection('alerts').doc(alertId).update({
        'likes': FieldValue.increment(1),
        'feedbackCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error liking alert: $e');
    }
  }

  Future<bool> hasUserResponded(String alertId, String userId) async {
    final doc = await _firestore.collection('feedback').doc('${alertId}_$userId').get();
    return doc.exists;
  }

  Future<void> reverifyAlert(String alertId) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}${AppConstants.reVerifyAlert}/$alertId');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to trigger verification: ${response.body}');
      }
      
      // The backend will update Firestore directly. 
      // The UI will react to the Firestore changes automatically via streams.
    } catch (e) {
      print('Error in reverifyAlert: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchLiveNews() async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/crisis-intelligence');
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> events = data['events'];
        
        // Map CrisisEvent format to what PostCard expects
        return events.map((ev) => {
          'link': ev['article_url'] ?? '',
          'source': (ev['sources'] as List).join(', '),
          'location': '${ev['location']['city']}, ${ev['location']['state']}',
          'published': ev['timestamp'],
          'severity': ev['severity'].toLowerCase(),
          'title': ev['title'],
          'description': ev['summary'],
          'full_content': ev['full_content'],
          'disaster_type': ev['disaster_type'],
          'confidence_score': (ev['trust_score'] * 100).toInt(),
          'trust_status': ev['trust_label'].toLowerCase(),
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error in fetchLiveNews: $e');
      return [];
    }
  }

  Future<String> chatAI(String message, {String? context}) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/chat');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'context': context,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'];
      }
      throw Exception('Failed to get AI response');
    } catch (e) {
      print('Error in chatAI: $e');
      return '❌ Connection error. Please ensure the backend is running.';
    }
  }

  /// Fetch next single news item from the streaming endpoint
  Future<Map<String, dynamic>?> fetchNextNewsItem() async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/news-stream');
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok' && data['item'] != null) {
          final item = data['item'] as Map<String, dynamic>;
          return {
            'link': '',
            'source': (item['sources'] as List?)?.map((s) => s['source_name'] ?? '').join(', ') ?? 'Live Feed',
            'location': '${item['location']?['city'] ?? 'Mumbai'}, ${item['location']?['state'] ?? 'Maharashtra'}',
            'published': item['timeAgo'] ?? 'Just now',
            'severity': (item['severity'] ?? 'low').toString().toLowerCase(),
            'title': item['title'] ?? 'Update',
            'description': item['summary'] ?? item['full_description'] ?? '',
            'disaster_type': item['disaster_type'] ?? 'other',
            'confidence_score': ((item['confidence_score'] ?? 0.7) * 100).toInt(),
            'trust_status': (item['trust_label'] ?? 'partial').toString().toLowerCase().contains('verified') ? 'verified' : 'partial',
            'stream_index': item['stream_index'] ?? 0,
          };
        }
      }
      return null;
    } catch (e) {
      print('Error fetching next news: $e');
      return null;
    }
  }

  /// Fetch next single alert from the streaming endpoint
  Future<Map<String, dynamic>?> fetchNextAlert() async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/alerts-stream');
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok' && data['item'] != null) {
          return data['item'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching next alert: $e');
      return null;
    }
  }
}
