import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseUrlProvider = StateProvider<String>((ref) {
  // Default to Render URL from .env
  return dotenv.env['API_BASE_URL'] ?? 'https://crisis-clarity.onrender.com';
});

final isNetworkConfiguredProvider = StateProvider<bool>((ref) => false);
