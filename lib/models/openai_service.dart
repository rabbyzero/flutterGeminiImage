import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service_base.dart';

/// OpenAI service implementation that extends the base AI service
class OpenAIService extends AIServiceBase {
  final String _modelName;

  OpenAIService({String? saveDirectory, String modelName = 'gpt-4-vision-preview'})
      : _modelName = modelName,
        super(saveDirectory: saveDirectory);

  @override
  String get modelName => _modelName;

  @override
  String get platform => 'OpenAI';

  @override
  Future<Map<String, dynamic>> analyzeImages(
    String prompt,
    List<Uint8List> imageBytesList,
    List<String?> mimeTypes,
  ) async {
    await initialize();

    // Create the messages payload for OpenAI
    final messages = [
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          ...imageBytesList.asMap().entries.map((entry) {
            final index = entry.key;
            final imageBytes = entry.value;
            final mimeType = mimeTypes[index] ?? 'image/jpeg';
            
            return {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mimeType;base64,${base64Encode(imageBytes)}'
              }
            };
          }).toList()
        ]
      }
    ];

    final requestBody = {
      'model': _modelName,
      'messages': messages,
      'max_tokens': 1000,
    };

    print('OpenAI Request Content: Prompt="$prompt", ImageCount=${imageBytesList.length}');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${apiKey!}',
    };

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await httpClient.post(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    );

    print('OpenAI Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      try {
        if (jsonResponse['choices'] != null && jsonResponse['choices'].length > 0) {
          final message = jsonResponse['choices'][0]['message'];
          if (message != null && message['content'] != null) {
            final generatedText = message['content'];
            return {'text': generatedText, 'image': null};
          }
        }
        return {'text': 'No text generated. Response: $jsonResponse'};
      } catch (e) {
        print('OpenAI parsing error: $e');
        return {'text': 'Error parsing response: $e'};
      }
    } else {
      print('OpenAI API Error: ${response.statusCode} ${response.body}');
      return {'text': 'Error: API returned ${response.statusCode}: ${response.body}'};
    }
  }

  @override
  Future<Map<String, dynamic>> generateText(String prompt) async {
    await initialize();

    final messages = [
      {'role': 'user', 'content': prompt}
    ];

    final requestBody = {
      'model': _modelName,
      'messages': messages,
      'max_tokens': 1000,
    };

    print('OpenAI Text Generation Request: "$prompt"');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${apiKey!}',
    };

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await httpClient.post(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    );

    print('OpenAI Text Generation Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      try {
        if (jsonResponse['choices'] != null && jsonResponse['choices'].length > 0) {
          final message = jsonResponse['choices'][0]['message'];
          if (message != null && message['content'] != null) {
            final generatedText = message['content'];
            return {'text': generatedText};
          }
        }
        return {'text': 'No text generated. Response: $jsonResponse'};
      } catch (e) {
        print('OpenAI parsing error: $e');
        return {'text': 'Error parsing response: $e'};
      }
    } else {
      print('OpenAI API Error: ${response.statusCode} ${response.body}');
      return {'text': 'Error: API returned ${response.statusCode}: ${response.body}'};
    }
  }
}