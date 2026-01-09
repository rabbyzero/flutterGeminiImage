import 'dart:convert';
import 'dart:typed_data';
import 'ai_service_base.dart';

class OpenAIService extends AIServiceBase {
  @override
  String get platform => 'OpenAI';

  @override
  String get modelName => 'GPT-4 Vision';
  
  final String baseUrl = 'https://api.openai.com/v1/chat/completions';

  OpenAIService({required super.saveDirectory});

  String _readApiKeyFromFile() {
    // Placeholder for reading API key from secure storage
    return '';
  }

  String _prepareRequestBody(String prompt, List<Uint8List> imageBytesList, List<String?> mimeTypes) {
    // Prepare the request body according to OpenAI API requirements
    final List<Map<String, dynamic>> imageContents = imageBytesList.asMap().entries.map((entry) {
      int index = entry.key;
      Uint8List bytes = entry.value;
      return {
        'type': 'image_url',
        'image_url': {
          'url': 'data:${mimeTypes[index] ?? "image/jpeg"};base64,${base64Encode(bytes)}'
        }
      };
    }).toList();

    final Map<String, dynamic> requestBody = {
      'model': 'gpt-4-vision-preview',
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            ...imageContents
          ]
        }
      ],
      'max_tokens': 300
    };

    return jsonEncode(requestBody);
  }

  @override
  Future<Map<String, dynamic>> analyzeImage(String prompt, List<Uint8List> imageBytesList, List<String?> mimeTypes) async {
    print('Sending request to OpenAI API...');
    print('Number of images: ${imageBytesList.length}');
    print('Prompt: $prompt');

    // Prepare request headers
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_readApiKeyFromFile()}',
    };

    // Prepare request body
    final requestBody = _prepareRequestBody(prompt, imageBytesList, mimeTypes);

    print('Request body size: ${requestBody.length} characters');

    // Send the request using the base class http client
    final response = await httpClient.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: requestBody,
    );

    print('OpenAI API response status: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('OpenAI API error: ${response.body}');
      return {
        'text': 'Error: ${response.statusCode} - ${response.body}',
        'image': null,
      };
    }

    // Parse the response
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      // Extract text response
      String textResponse = '';
      if (jsonResponse['choices'] != null && jsonResponse['choices'].isNotEmpty) {
        textResponse = jsonResponse['choices'][0]['message']['content'] ?? '';
      }
      
      // Extract image if present in response
      Uint8List? imageResponse;
      // Note: GPT-4 Vision typically doesn't return generated images, only text responses
      
      return {
        'text': textResponse,
        'image': imageResponse,
      };
    } catch (e) {
      print('Error parsing OpenAI API response: $e');
      return {
        'text': 'Error processing response from OpenAI API',
        'image': null,
      };
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeImages(String prompt, List<Uint8List> imageBytesList, List<String?> mimeTypes) async {
    return analyzeImage(prompt, imageBytesList, mimeTypes);
  }

  @override
  Future<Map<String, dynamic>> generateText(String prompt) async {
    // For now, just return a placeholder
    // Actual implementation would send a text-only request to the API
    return {'text': 'Generated text for: $prompt', 'image': null};
  }
}