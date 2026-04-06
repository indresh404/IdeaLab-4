import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/alert_model.dart';

class AlertRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AlertModel>> getActiveAlerts(String ward) {
    return _firestore.collection('alerts')
        .where('isActive', isEqualTo: true)
        .where('affectedZones', arrayContains: ward)
        .snapshots()
        .map((snapshot) {
          final alerts = snapshot.docs
              .map((doc) => AlertModel.fromFirestore(doc))
              .toList();
          // Sort client-side to avoid index requirement
          alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return alerts;
        });
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

  Future<bool> hasUserResponded(String alertId, String userId) async {
    final doc = await _firestore.collection('feedback').doc('${alertId}_$userId').get();
    return doc.exists;
  }
}
