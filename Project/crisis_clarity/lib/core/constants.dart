import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Backend API URL loaded from .env
  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.26:8000';
  }

  // API Endpoints
  static const String verifyAlert = '/verify-alert';
  static const String reVerifyAlert = '/re-verify';
  static const String demoScenarios = '/demo-scenarios';
  static const String healthCheck = '/health';
}
