import 'package:cloud_firestore/cloud_firestore.dart';
import '../../alerts/domain/alert_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    await docRef.set({
      ...alertData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'understood': 0,
      'notUnderstood': 0,
      'totalViews': 0,
    });
  }

  Future<void> postSafetyInstructions(String disasterType, List<Map<String, String>> steps) async {
    await _firestore.collection('safetyInstructions').doc(disasterType).set({
      'steps': steps,
    });
  }
}
