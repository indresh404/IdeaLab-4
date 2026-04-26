import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  final String id;
  final String titleEn;
  final String titleHi;
  final String titleMr;
  final String descriptionEn;
  final String descriptionHi;
  final String descriptionMr;
  final String simplifiedEn;
  final String simplifiedHi;
  final String simplifiedMr;
  final String disasterType; // flood, storm, fire, etc.
  final String severity; // low, medium, high, critical
  final List<String> affectedZones;
  final String postedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int understood;
  final int notUnderstood;
  final int totalViews;
  final int trustScore; // 0-100
  final String trustStatus; // verified, partial, fake
  final List<String> sourcesChecked;
  final String verificationReason;
  final bool hasConflict;
  final bool usingRealData;

  AlertModel({
    required this.id,
    required this.titleEn,
    required this.titleHi,
    required this.titleMr,
    required this.descriptionEn,
    required this.descriptionHi,
    required this.descriptionMr,
    required this.simplifiedEn,
    required this.simplifiedHi,
    required this.simplifiedMr,
    required this.disasterType,
    required this.severity,
    required this.affectedZones,
    required this.postedBy,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.understood = 0,
    this.notUnderstood = 0,
    this.totalViews = 0,
    this.trustScore = 50,
    this.trustStatus = 'partial',
    this.sourcesChecked = const [],
    this.verificationReason = 'Awaiting AI verification...',
    this.hasConflict = false,
    this.usingRealData = false,
  });

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlertModel(
      id: doc.id,
      titleEn: data['title'] ?? '',
      titleHi: data['titleHi'] ?? '',
      titleMr: data['titleMr'] ?? '',
      descriptionEn: data['description'] ?? '',
      descriptionHi: data['descriptionHi'] ?? '',
      descriptionMr: data['descriptionMr'] ?? '',
      simplifiedEn: data['simplifiedEn'] ?? '',
      simplifiedHi: data['simplifiedHi'] ?? '',
      simplifiedMr: data['simplifiedMr'] ?? '',
      disasterType: data['disasterType'] ?? 'other',
      severity: data['severity'] ?? 'low',
      affectedZones: List<String>.from(data['affectedZones'] ?? []),
      postedBy: data['postedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      understood: data['understood'] ?? 0,
      notUnderstood: data['notUnderstood'] ?? 0,
      totalViews: data['totalViews'] ?? 0,
      trustScore: data['trustScore'] ?? 50,
      trustStatus: data['trustStatus'] ?? 'partial',
      sourcesChecked: List<String>.from(data['sourcesChecked'] ?? []),
      verificationReason: data['verificationReason'] ?? 'Awaiting AI verification...',
      hasConflict: data['hasConflict'] ?? false,
      usingRealData: data['usingRealData'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': titleEn,
      'titleHi': titleHi,
      'titleMr': titleMr,
      'description': descriptionEn,
      'descriptionHi': descriptionHi,
      'descriptionMr': descriptionMr,
      'simplifiedEn': simplifiedEn,
      'simplifiedHi': simplifiedHi,
      'simplifiedMr': simplifiedMr,
      'disasterType': disasterType,
      'severity': severity,
      'affectedZones': affectedZones,
      'postedBy': postedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'understood': understood,
      'notUnderstood': notUnderstood,
      'totalViews': totalViews,
      'trustScore': trustScore,
      'trustStatus': trustStatus,
      'sourcesChecked': sourcesChecked,
      'verificationReason': verificationReason,
      'hasConflict': hasConflict,
      'usingRealData': usingRealData,
    };
  }

  // Helper to get localized title based on language code
  String getLocalizedTitle(String lang) {
    switch (lang) {
      case 'hi': return titleHi;
      case 'mr': return titleMr;
      default: return titleEn;
    }
  }

  // Helper to get localized simplified description
  String getLocalizedSimplified(String lang) {
    switch (lang) {
      case 'hi': return simplifiedHi;
      case 'mr': return simplifiedMr;
      default: return simplifiedEn;
    }
  }
}
