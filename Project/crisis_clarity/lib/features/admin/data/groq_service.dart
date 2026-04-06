import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  final String? apiKey;
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  GroqService({this.apiKey});

  Future<Map<String, dynamic>> simplifyAlert(String rawText) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('Groq API Key is missing');
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a disaster alert AI for Mumbai. Given a raw alert, return a JSON object with these exact keys: titleEn, titleHi, titleMr, descriptionEn, descriptionHi, descriptionMr, simplifiedEn, simplifiedHi, simplifiedMr, disasterType (one of: flood/storm/fire/evacuation/cyclone/earthquake/other), severity (low/medium/high/critical), safetyStepsEn (array of strings), safetyStepsHi (array), safetyStepsMr (array). Return ONLY valid JSON, no markdown.'
          },
          {'role': 'user', 'content': rawText}
        ],
        'temperature': 0.1,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String content = data['choices'][0]['message']['content'];
      return jsonDecode(content);
    } else {
      throw Exception('Groq API error: ${response.body}');
    }
  }
}
