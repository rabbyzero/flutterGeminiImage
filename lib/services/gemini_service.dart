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
  
  @override
  String get displayName => '$platform - $modelName';
  
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
      // Production code shouldn't use print statements
      // print('Failed to read API key from file: $e');
      return '';
    }
  }

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

    // Only enable Google Search for Gemini 3 models (Gemini 2.5 Flash usage leads to 400 Bad Request)
    if (_modelId.contains('gemini-3')) {
      requestBody['tools'] = [
        {'googleSearch': {}}
      ];
    }

    if (config != null) {
      requestBody['generationConfig'] = {
        'imageConfig': config,
      };
    }

    return jsonEncode(requestBody);
  }

  @override
  Future<Map<String, dynamic>> analyzeImages(String prompt, List<Uint8List> imageBytesList, List<String?> mimeTypes, {Map<String, dynamic>? config}) async {
    // Production code shouldn't use print statements
    // print('Sending request to Gemini API...');
    // print('Number of images: ${imageBytesList.length}');
    // print('Prompt: $prompt');
    
    Map<String, dynamic>? apiConfig;
    if (config != null) {
      apiConfig = Map<String, dynamic>.from(config);
      if (apiConfig.containsKey('proxy')) {
        await updateClientProxy(apiConfig['proxy'] as String?);
        apiConfig.remove('proxy');
      }
       // print('Config: $config');
    }

    // Prepare request headers
    final apiKey = await _readApiKeyFromFile();
    final headers = {
      'x-goog-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    // Prepare request body
    final requestBody = _prepareRequestBody(prompt, imageBytesList, mimeTypes, config: apiConfig);
    
    // Generate curl command
    final curlHeaders = Map<String, String>.from(headers);
    curlHeaders['x-goog-api-key'] = '\$(cat assets/api_key.txt)';
    final curlCommand = _generateCurlCommand('POST', baseUrl, curlHeaders, requestBody);

    // Send the request using the base class http client
    http.Response response;
    try {
      response = await httpClient.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: requestBody,
      );
    } on SocketException catch (_) {
      // Production code shouldn't use print statements
      // print('Network error: $e');
      return {
        'error': 'Network connection failed. Please check your internet connection.',
        'text': null,
        'images': <Uint8List>[],
        'curl': curlCommand,
      };
    } on HandshakeException catch (_) {
      // Production code shouldn't use print statements
      // print('SSL/TLS error: $e');
      return {
        'error': 'Secure connection failed. Please check your network settings.',
        'text': null,
        'images': <Uint8List>[],
        'curl': curlCommand,
      };
    } catch (_) {
      // Production code shouldn't use print statements
      // print('Request failed: $e');
      return {
        'error': 'Request failed',
        'text': null,
        'images': <Uint8List>[],
        'curl': curlCommand,
      };
    }

    // Production code shouldn't use print statements
    // print('Gemini API response status: ${response.statusCode}');
    if (response.statusCode != 200) {
      // print('Gemini API error: ${response.body}');
      
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
        'images': <Uint8List>[],
        'curl': curlCommand,
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
      List<Uint8List> imagesResponse = [];
      if (jsonResponse.containsKey('promptFeedback')){
        // print(jsonResponse['promptFeedback']);
        textResponse += jsonResponse['promptFeedback']['blockReason'] ?? '';
      }


      Map<String, dynamic>? groundingMetadata;

      if (jsonResponse['candidates'] != null && jsonResponse['candidates'].isNotEmpty) {
        final candidate = jsonResponse['candidates'][0];
        
        if (candidate.containsKey('groundingMetadata')) {
          groundingMetadata = candidate['groundingMetadata'];
        }

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
                    final imageBytes = base64Decode(inlineData['data']);
                    imagesResponse.add(imageBytes);
                    await saveGeneratedImage(imageBytes);
                  } catch (e) {
                    // Production code shouldn't use print statements
                    // print('Error decoding image data: $e');
                  }
                }
              }
            }
          }
        }
      }
      
      return {
        'text': textResponse,
        'images': imagesResponse,
        'usage': usageMetadata,
        'groundingMetadata': groundingMetadata,
        'curl': curlCommand,
      };
    } catch (e) {
      // Production code shouldn't use print statements
      // print('Error parsing Gemini API response: $e');
      return {
        'text': 'Error processing response from Gemini API',
        'images': <Uint8List>[],
        'curl': curlCommand,
      };
    }
  }

  @override
  Future<Map<String, dynamic>> generateText(String prompt) async {
    // For now, just return a placeholder
    // Actual implementation would send a text-only request to the API
    return {'text': 'Generated text for: $prompt', 'image': null};
  }

  @override
  Future<String> getCurlCommand(String prompt, List<Uint8List> imageBytesList, List<String?> mimeTypes, {Map<String, dynamic>? config}) async {
    Map<String, dynamic>? apiConfig;
    if (config != null) {
      apiConfig = Map<String, dynamic>.from(config);
      // We don't necessarily need to update the actual client proxy here, 
      // but we need to know what it would be. 
      // For simplicity and consistency, let's assume the config reflects the desired state.
      if (apiConfig.containsKey('proxy')) {
        // We use the proxy from config for the curl command
        // But we won't update the actual client here to avoid side effects during typing
        // Instead we'll pass it temporarily if we refactor _generateCurlCommand 
        // OR we just rely on _currentProxy if it was set elsewhere? 
        // Actually, the user might type a proxy and expect the curl to update BEFORE running.
        // So we should probably use the proxy from config if present.
      }
    }
    
    // final apiKey = await _readApiKeyFromFile();
    // For the CURL command, we use the file path instead of the actual key
    // This assumes the user is running the command from the project root
    // $(cat ...) works on POSIX shells (Linux/macOS/Git Bash)
    final headers = {
      'x-goog-api-key': '\$(cat assets/api_key.txt)',
      'Content-Type': 'application/json',
    };
    
    // Using apiConfig from which proxy was removed if using the logic from analyzeImages
    // But here we want to handle it slightly differently to not mutate client?
    // Let's copy the logic but handle proxy explicitly for the string generation.

    String? proxyToUse = config?['proxy'];
    
    // Create a body config that excludes the proxy key
    Map<String, dynamic>? bodyConfig;
    if (config != null) {
      bodyConfig = Map<String, dynamic>.from(config);
      bodyConfig.remove('proxy');
    }

    final requestBody = _prepareRequestBody(prompt, imageBytesList, mimeTypes, config: bodyConfig);
    
    // We need to pass the proxy to _generateCurlCommand
    return _generateCurlCommand('POST', baseUrl, headers, requestBody, proxyOverride: proxyToUse);
  }

  String _generateCurlCommand(String method, String url, Map<String, String> headers, String? body, {String? proxyOverride}) {
    StringBuffer curlCmd = StringBuffer('curl -X $method "$url"');
    
    headers.forEach((key, value) {
      curlCmd.write(' \\\n  -H "$key: $value"');
    });

    final proxy = proxyOverride ?? currentProxy;
    if (proxy != null && proxy.isNotEmpty) {
       curlCmd.write(' \\\n  --proxy "$proxy"');
    }
    
    if (body != null) {
      // Escape single quotes for shell safety if wrapping in single quotes
      String escapedBody = body.replaceAll("'", "'\\''"); 
      curlCmd.write(" \\\n  -d '$escapedBody'");
    }

    return curlCmd.toString();
  }
}