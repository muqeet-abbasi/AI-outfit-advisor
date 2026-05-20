import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiKey =
      'AIzaSyBvBA71pjqwwAUpJIx2wDN0HWbRIwuScZU'; // <-- REPLACE WITH YOUR API KEY';
  static const String _model = 'gemini-2.5-flash'; // correct string
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static const String _systemPrompt = '''
You are a fashion stylist. Analyze this outfit and respond in this exact format only:

STYLE_PERSONA: [2-3 word creative label]
OVERALL_STYLE: [2 sentences max]
COLOR_PALETTE: [1 sentence]
OCCASION: [1 sentence]
FIT_ASSESSMENT: [1 sentence]
STYLE_SCORE: [0-100]
STRENGTHS:
- [item]
- [item]
IMPROVEMENTS:
- [item]
- [item]
ACCESSORIES:
- [item]
- [item]
ALTERNATIVES:
- [item]
- [item]
SEASONAL_ADVICE: [1 sentence]
''';

  Future<String> analyzeOutfit(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = _getMimeType(imageFile.path);

    final requestBody = {
      "contents": [
        {
          "parts": [
            {"text": _systemPrompt},
            {
              "inline_data": {"mime_type": mimeType, "data": base64Image},
            },
          ],
        },
      ],
      "generationConfig": {
        "temperature": 0.7,
        "maxOutputTokens": 3000,
        "thinkingConfig": {"thinkingBudget": 0},
      },
    };

    // Retry up to 3 times with exponential backoff
    for (int attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        final waitSeconds = pow(2, attempt).toInt() + Random().nextInt(3);
        await Future.delayed(Duration(seconds: waitSeconds));
      }

      try {
        final response = await http
            .post(
              Uri.parse('$_baseUrl?key=$apiKey'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 40));

        print('Gemini response status: ${response.statusCode}');
        print('Gemini response body: ${response.body}');
        final data = jsonDecode(response.body);

        print('Gemini response: $data');
        if (response.statusCode == 200) {
          final text =
              data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text != null) return text;
          throw Exception('Empty response from Gemini');
        }

        final code = data['error']?['code'];
        final message = data['error']?['message'] ?? 'Unknown error';

        // Retry on 503 (overloaded) or 429 (rate limit)
        if ((code == 503 || code == 429) && attempt < 2) {
          continue; // retry
        }

        throw Exception('Gemini error ($code): $message');
      } on SocketException {
        if (attempt == 2) throw Exception('No internet connection');
      } on Exception catch (e) {
        if (attempt == 2) rethrow;
        if (e.toString().contains('503') || e.toString().contains('429'))
          continue;
        rethrow;
      }
    }

    throw Exception('All retry attempts failed. Please try again in a moment.');
  }

  String _getMimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
