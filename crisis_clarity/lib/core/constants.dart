import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Backend API URL loaded from .env
  static String get baseUrl {
    // This pulls the URL from your .env file at the root of the project
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  }

  // API Endpoints
  static const String verifyAlert = '/verify-alert';
  static const String reVerifyAlert = '/re-verify';
  static const String demoScenarios = '/demo-scenarios';
  static const String healthCheck = '/health';
}
