import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'ai_service_base.dart';

class GeminiService extends AIServiceBase {
  final String _modelId;
  final String _displayName;

  @override
  String get platform => 'Google';

  @override
  String get modelName => _displayName;
  
  late final String baseUrl;

  GeminiService({
    required super.saveDirectory, 
    String modelId = 'gemini-2.5-flash-image',
    String displayName = 'Gemini 2.5 Flash',
  }) : _modelId = modelId, _displayName = displayName {
    baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_modelId:generateContent';
  }

  Future<String> _readApiKeyFromFile() async {
    try {
      final apiKey = await rootBundle.loadString('assets/api_key.txt');
      return apiKey.trim();
    } catch (e) {
      print('Failed to read API key from file: $e');
      return '';
    }
  }

  @override
  String _prepareRequestBody(String prompt, List<Uint8List> imageBytesList, List<String?> mimeTypes, {Map<String, dynamic>? config}) {
    // Prepare the request body according to Gemini API requirements
    final List<Map<String, dynamic>> contents = [
      {
        'role': 'user',
        'parts': [
          {'text': prompt},
          ...imageBytesList.asMap().entries.map((entry) {
            int index = entry.key;
            Uint8List bytes = entry.value;
            return {
              'inline_data': {
                'mime_type': mimeTypes[index] ?? 'image/jpeg',
                'data': base64Encode(bytes),
              }
            };
          })
        ]
      }
    ];

    final Map<String, dynamic> requestBody = {
      'contents': contents,
    };

    if (config != null) {
      requestBody['generationConfig'] = {
        'imageConfig': config,
      };
    }

    return jsonEncode(requestBody);
  }

  Future<Map<String, dynamic>> analyzeImage(String prompt, List<Uint8List> imageBytesList, List<String?> mimeTypes, {Map<String, dynamic>? config}) async {
    print('Sending request to Gemini API...');
    print('Number of images: ${imageBytesList.length}');
    print('Prompt: $prompt');
    if (config != null) {
      print('Config: $config');
    }

    // Prepare request headers
    final apiKey = await _readApiKeyFromFile();
    final headers = {
      'x-goog-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    // Prepare request body
    final requestBody = _prepareRequestBody(prompt, imageBytesList, mimeTypes, config: config);
    print(baseUrl);

    print('Request body size: ${requestBody.length} characters');

    // Send the request using the base class http client
    http.Response response;
    try {
      response = await httpClient.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: requestBody,
      );
    } on SocketException catch (e) {
      print('Network error: $e');
      return {
        'error': 'Network connection failed. Please check your internet connection.',
        'text': null,
        'image': null,
      };
    } on HandshakeException catch (e) {
      print('SSL/TLS error: $e');
      return {
        'error': 'Secure connection failed. Please check your network settings.',
        'text': null,
        'image': null,
      };
    } catch (e) {
      print('Request failed: $e');
      return {
        'error': 'Request failed: $e',
        'text': null,
        'image': null,
      };
    }

    print('Gemini API response status: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('Gemini API error: ${response.body}');
      
      String errorMessage = 'API Error (${response.statusCode})';
      try {
        final errorJson = jsonDecode(response.body);
        if (errorJson['error'] != null && errorJson['error']['message'] != null) {
          errorMessage = errorJson['error']['message'];
        }
      } catch (e) {
        // Fallback to raw body if not valid JSON
        errorMessage = response.body;
      }
      
      String userFriendlyMessage = errorMessage;
      
      // Handle specific status codes
      switch (response.statusCode) {
        case 400:
          userFriendlyMessage = 'Bad Request: $errorMessage';
          if (errorMessage.contains('INVALID_ARGUMENT')) {
             userFriendlyMessage = 'Invalid parameters. Please check your image format or prompt.';
          }
          break;
        case 401:
          userFriendlyMessage = 'Unauthorized: Invalid API Key. Please check your assets/api_key.txt file.';
          break;
        case 403:
          userFriendlyMessage = 'Forbidden: Access denied.';
          if (errorMessage.contains('location is not supported')) {
            userFriendlyMessage = 'Location not supported. You may need to use a proxy or VPN.';
          } else if (errorMessage.contains('quota')) {
            userFriendlyMessage = 'Quota exceeded. Please check your Google Cloud Console usage.';
          }
          break;
        case 404:
          userFriendlyMessage = 'Model not found. The model $_modelId might not exist or you don\'t have access to it.';
          break;
        case 429:
          userFriendlyMessage = 'Too Many Requests. Please slow down.';
          break;
        case 500:
        case 502:
        case 503:
        case 504:
          userFriendlyMessage = 'Gemini Service Error (${response.statusCode}). Please try again later.';
          break;
      }

      return {
        'error': userFriendlyMessage,
        'text': 'Error: $userFriendlyMessage',
        'image': null,
      };
    }

    // Parse the response
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      
      Map<String, dynamic>? usageMetadata;
      if (jsonResponse.containsKey('usageMetadata')) {
        usageMetadata = jsonResponse['usageMetadata'];
      }

      String textResponse = '';
      Uint8List? imageResponse;
      if (jsonResponse.containsKey('promptFeedback')){
        print(jsonResponse['promptFeedback']);
        textResponse += jsonResponse['promptFeedback']['blockReason'] ?? '';
      }


      if (jsonResponse['candidates'] != null && jsonResponse['candidates'].isNotEmpty) {
        final candidate = jsonResponse['candidates'][0];
        final content = candidate['content'];

        if (content == null) {
          textResponse += candidate['finishReason'] ?? '';
        }

        if (content != null && content['parts'] != null) {
          final parts = content['parts'] as List;
          
          for (var part in parts) {
            if (part is Map) {
              // Extract text
              if (part.containsKey('text')) {
                textResponse += part['text'] ?? '';
              }
              
              // Extract image (handle both snake_case and camelCase)
              final inlineData = part['inline_data'] ?? part['inlineData'];
              if (inlineData != null && inlineData is Map) {
                if (inlineData.containsKey('data')) {
                  try {
                    imageResponse = base64Decode(inlineData['data']);
                    await saveGeneratedImage(imageResponse);
                  } catch (e) {
                    print('Error decoding image data: $e');
                  }
                }
              }
            }
          }
        }
      }
      
      return {
        'text': textResponse,
        'image': imageResponse,
        'usage': usageMetadata,
      };
    } catch (e) {
      print('Error parsing Gemini API response: $e');
      return {
        'text': 'Error processing response from Gemini API',
        'image': null,
      };
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeImages(String prompt, List<Uint8List> imageBytesList, List<String?> mimeTypes, {Map<String, dynamic>? config}) async {
    return analyzeImage(prompt, imageBytesList, mimeTypes, config: config);
  }

  @override
  Future<Map<String, dynamic>> generateText(String prompt) async {
    // For now, just return a placeholder
    // Actual implementation would send a text-only request to the API
    return {'text': 'Generated text for: $prompt', 'image': null};
  }
}