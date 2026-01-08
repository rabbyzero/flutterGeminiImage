import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service_base.dart';

/// Gemini service implementation that extends the base AI service
class GeminiService extends AIServiceBase {
  final String _modelName;

  GeminiService({String? saveDirectory, String modelName = 'gemini-2.5-flash-image'})
      : _modelName = modelName,
        super(saveDirectory: saveDirectory);

  @override
  String get modelName => _modelName;

  @override
  String get platform => 'Gemini';

  @override
  Future<Map<String, dynamic>> analyzeImages(
    String prompt,
    List<Uint8List> imageBytesList,
    List<String?> mimeTypes,
  ) async {
    await initialize();

    final parts = <Map<String, dynamic>>[
      {'text': prompt}
    ];

    // Add all images to the request
    for (var i = 0; i < imageBytesList.length; i++) {
      if (mimeTypes[i] != null) {
        parts.add({
          'inline_data': {
            'mime_type': mimeTypes[i],
            'data': base64Encode(imageBytesList[i])
          }
        });
      }
    }

    final requestBody = {
      'contents': [
        {
          'parts': parts
        }
      ]
    };

    print('Gemini Request Content: Prompt="$prompt", ImageCount=${imageBytesList.length}');

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=${apiKey!}');
    final response = await httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    print('Gemini Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      try {
        final candidates = jsonResponse['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final candidate = candidates[0];
          final content = candidate['content'];
          if (content != null) {
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              String? generatedText;
              Uint8List? generatedImage;

              for (var part in parts) {
                print('Gemini Part keys: ${part.keys}');
                if (part.containsKey('text')) {
                  generatedText = (generatedText ?? '') + part['text'];
                }
                
                // Handle both snake_case (API spec) and camelCase (observed in some responses)
                final inlineData = part['inline_data'] ?? part['inlineData'];
                if (inlineData != null) {
                  if (inlineData.containsKey('data')) {
                    generatedImage = base64Decode(inlineData['data']);
                    // Save the generated image using the method from the base class
                    await saveGeneratedImage(generatedImage);
                  } else {
                    print('inlineData key found, but missing "data" field. Keys: ${inlineData.keys}');
                  }
                }
              }
              
              if (generatedText == null && generatedImage == null) {
                return {'text': 'Debug: Parsed parts but found no content. Raw parts: $parts'};
              }

              return {
                'text': generatedText,
                'image': generatedImage,
              };
            }
          }
        }
        if (jsonResponse['promptFeedback'] != null) {
           return {'text': "Safety Block: ${jsonResponse['promptFeedback']}"};
        }
        return {'text': 'No text generated. Response: $jsonResponse'};
      } catch (e) {
           print('Gemini parsing error: $e');
           return {'text': 'Error parsing response: $e'};
      }
    } else {
      print('Gemini API Error: ${response.statusCode} ${response.body}');
      return {'text': 'Error: API returned ${response.statusCode}: ${response.body}'};
    }
  }

  @override
  Future<Map<String, dynamic>> generateText(String prompt) async {
    await initialize();

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    };

    print('Gemini Text Generation Request: "$prompt"');

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=${apiKey!}');
    final response = await httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    print('Gemini Text Generation Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      try {
        final candidates = jsonResponse['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final candidate = candidates[0];
          final content = candidate['content'];
          if (content != null) {
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              String? generatedText;

              for (var part in parts) {
                if (part.containsKey('text')) {
                  generatedText = (generatedText ?? '') + part['text'];
                }
              }
              
              return {'text': generatedText ?? ''};
            }
          }
        }
        if (jsonResponse['promptFeedback'] != null) {
           return {'text': "Safety Block: ${jsonResponse['promptFeedback']}"};
        }
        return {'text': 'No text generated. Response: $jsonResponse'};
      } catch (e) {
           print('Gemini parsing error: $e');
           return {'text': 'Error parsing response: $e'};
      }
    } else {
      print('Gemini API Error: ${response.statusCode} ${response.body}');
      return {'text': 'Error: API returned ${response.statusCode}: ${response.body}'};
    }
  }
}