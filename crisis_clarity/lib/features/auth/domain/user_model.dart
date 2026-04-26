import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String? email;
  final String location; // Ward/Zone
  final String preferredLanguage; // en, hi, mr
  final String? telegramId;
  final bool telegramLinked;
  final String role; // citizen, admin
  final int? age;
  final String? gender;
  final String? fcmToken;
  final DateTime createdAt;
  final String? telegramChatId;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email,
    required this.location,
    required this.preferredLanguage,
    this.telegramId,
    this.telegramLinked = false,
    this.role = 'citizen',
    this.age,
    this.gender,
    this.fcmToken,
    required this.createdAt,
    this.telegramChatId,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      location: data['location'] ?? '',
      preferredLanguage: data['preferredLanguage'] ?? 'en',
      telegramId: data['telegramId'],
      telegramLinked: data['telegramLinked'] ?? false,
      role: data['role'] ?? 'citizen',
      age: data['age'],
      gender: data['gender'],
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      telegramChatId: data['telegramChatId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'location': location,
      'preferredLanguage': preferredLanguage,
      'telegramId': telegramId,
      'telegramLinked': telegramLinked,
      'role': role,
      'age': age,
      'gender': gender,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'telegramChatId': telegramChatId,
    };
  }
}
