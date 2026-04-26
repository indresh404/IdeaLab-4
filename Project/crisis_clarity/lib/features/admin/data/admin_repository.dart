import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../alerts/domain/alert_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String baseUrl;

  AdminRepository({required this.baseUrl});

  Stream<List<AlertModel>> getAllAlerts() {
    return _firestore.collection('alerts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AlertModel.fromFirestore(doc))
            .toList());
  }

  Future<void> postAlert(Map<String, dynamic> alertData) async {
    final docRef = _firestore.collection('alerts').doc();
    final alertId = docRef.id;

    await docRef.set({
      ...alertData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'understood': 0,
      'notUnderstood': 0,
      'totalViews': 0,
    });

    // Trigger AI Verification Pipeline via Backend API
    try {
      final url = Uri.parse('${baseUrl}${AppConstants.verifyAlert}');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'alertId': alertId, 'scenario': null}),
      );
    } catch (e) {
      print('Error triggering AI verification: $e');
    }
  }

  Future<void> postSafetyInstructions(String disasterType, List<Map<String, String>> steps) async {
    await _firestore.collection('safetyInstructions').doc(disasterType).set({
      'steps': steps,
    });
  }
}
