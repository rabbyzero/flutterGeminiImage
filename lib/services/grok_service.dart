import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import '../utils/curl_generator.dart';
import 'ai_service_base.dart';

class GrokService extends AIServiceBase {
  final String _modelId;
  final String _displayName;

  @override
  String get platform => 'xAI';

  @override
  String get modelName => _displayName;

  @override
  String get displayName => '$platform - $modelName';

  static const String _baseUrl = 'https://api.x.ai/v1';
  String get _imageGenerationUrl => '$_baseUrl/images/generations';
  String get _imageEditUrl => '$_baseUrl/images/edits';

  GrokService({
    required super.saveDirectory,
    String modelId = 'grok-imagine-image-pro',
    String displayName = 'Grok Imagine Image Pro',
  })  : _modelId = modelId,
        _displayName = displayName;

  Future<String> _readApiKeyFromFile() async {
    try {
      final apiKey = await rootBundle.loadString('assets/xai_api_key.txt');
      return apiKey.trim();
    } catch (e) {
      return '';
    }
  }

  Map<String, String> _buildHeaders(String apiKey) {
    return {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
  }

  String _prepareImageGenerationBody(String prompt,
      {Map<String, dynamic>? config}) {
    final Map<String, dynamic> requestBody = {
      'model': _modelId,
      'prompt': prompt,
      'n': 1,
      'response_format': 'b64_json',
    };

    if (config != null && config.containsKey('imageSize')) {
      requestBody['size'] = config['imageSize'];
    }

    return jsonEncode(requestBody);
  }

  String _prepareImageEditBody(String prompt, List<Uint8List> imageBytesList,
      List<String?> mimeTypes,
      {Map<String, dynamic>? config}) {
    final Map<String, dynamic> requestBody = {
      'model': _modelId,
      'prompt': prompt,
      'n': 1,
      'response_format': 'b64_json',
      'image': {
        'url': 'data:${mimeTypes.isNotEmpty ? mimeTypes[0] ?? "image/jpeg" : "image/jpeg"};base64,${base64Encode(imageBytesList[0])}'
      },
    };

    if (config != null && config.containsKey('imageSize')) {
      requestBody['size'] = config['imageSize'];
    }

    return jsonEncode(requestBody);
  }

  Map<String, dynamic>? _buildErrorResponse(
      http.Response response, String curlCommand) {
    if (response.statusCode == 200) return null;

    String errorMessage = 'API Error (${response.statusCode})';
    try {
      final errorJson = jsonDecode(response.body);
      if (errorJson['error'] != null) {
        errorMessage = errorJson['error']['message'] ??
            errorJson['error'].toString();
      }
    } catch (_) {
      errorMessage = response.body;
    }

    String userFriendlyMessage;
    switch (response.statusCode) {
      case 400:
        userFriendlyMessage = 'Bad Request: $errorMessage';
        break;
      case 401:
        userFriendlyMessage =
            'Unauthorized: Invalid xAI API Key. Please check your assets/xai_api_key.txt file.';
        break;
      case 403:
        userFriendlyMessage = 'Forbidden: Access denied. $errorMessage';
        break;
      case 404:
        userFriendlyMessage =
            'Model not found. The model $_modelId might not exist or you don\'t have access to it.';
        break;
      case 429:
        userFriendlyMessage =
            'Rate limit exceeded. Please slow down and try again later.';
        break;
      case 500:
      case 502:
      case 503:
      case 504:
        userFriendlyMessage =
            'xAI Service Error (${response.statusCode}). Please try again later.';
        break;
      default:
        userFriendlyMessage = errorMessage;
    }

    return {
      'error': userFriendlyMessage,
      'text': 'Error: $userFriendlyMessage',
      'images': <Uint8List>[],
      'curl': curlCommand,
    };
  }

  @override
  Future<Map<String, dynamic>> analyzeImages(
    String prompt,
    List<Uint8List> imageBytesList,
    List<String?> mimeTypes, {
    Map<String, dynamic>? config,
  }) async {
    Map<String, dynamic>? apiConfig;
    if (config != null) {
      apiConfig = Map<String, dynamic>.from(config);
      if (apiConfig.containsKey('proxy')) {
        await updateClientProxy(apiConfig['proxy'] as String?);
        apiConfig.remove('proxy');
      }
    }

    final apiKey = await _readApiKeyFromFile();
    final headers = _buildHeaders(apiKey);

    // Use image generation endpoint when no input images,
    // image edit endpoint when images are provided
    final bool useImageGeneration = imageBytesList.isEmpty;
    final String url =
        useImageGeneration ? _imageGenerationUrl : _imageEditUrl;
    final String requestBody = useImageGeneration
        ? _prepareImageGenerationBody(prompt, config: apiConfig)
        : _prepareImageEditBody(prompt, imageBytesList, mimeTypes, config: apiConfig);

    final curlCommand = CurlGenerator.generate(
      method: 'POST',
      url: url,
      headers: headers,
      body: requestBody,
      headerReplacements: {
        'Authorization': 'Bearer \$(cat assets/xai_api_key.txt)',
      },
    );

    http.Response response;
    try {
      response = await httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: requestBody,
      );
    } on SocketException catch (_) {
      return {
        'error':
            'Network connection failed. Please check your internet connection.',
        'text': null,
        'images': <Uint8List>[],
        'curl': curlCommand,
      };
    } on HandshakeException catch (_) {
      return {
        'error':
            'Secure connection failed. Please check your network settings.',
        'text': null,
        'images': <Uint8List>[],
        'curl': curlCommand,
      };
    } catch (_) {
      return {
        'error': 'Request failed',
        'text': null,
        'images': <Uint8List>[],
        'curl': curlCommand,
      };
    }

    final errorResult = _buildErrorResponse(response, curlCommand);
    if (errorResult != null) return errorResult;

    try {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      // Both endpoints return the same response format
      return await _parseImageGenerationResponse(jsonResponse, curlCommand);
    } catch (e) {
      return {
        'text': 'Error processing response from xAI API',
        'images': <Uint8List>[],
        'curl': curlCommand,
      };
    }
  }

  Future<Map<String, dynamic>> _parseImageGenerationResponse(
    Map<String, dynamic> jsonResponse,
    String curlCommand,
  ) async {
    String textResponse = '';
    List<Uint8List> imagesResponse = [];

    final data = jsonResponse['data'] as List?;
    if (data != null) {
      for (var item in data) {
        if (item is Map) {
          if (item.containsKey('revised_prompt')) {
            textResponse += item['revised_prompt'] ?? '';
          }
          if (item.containsKey('b64_json')) {
            try {
              final imageBytes = base64Decode(item['b64_json']);
              imagesResponse.add(imageBytes);
              await saveGeneratedImage(imageBytes);
            } catch (_) {}
          } else if (item.containsKey('url')) {
            try {
              final imageResponse =
                  await httpClient.get(Uri.parse(item['url']));
              if (imageResponse.statusCode == 200) {
                imagesResponse.add(imageResponse.bodyBytes);
                await saveGeneratedImage(imageResponse.bodyBytes);
              }
            } catch (_) {}
          }
        }
      }
    }

    Map<String, dynamic>? usageMetadata;
    if (jsonResponse.containsKey('usage')) {
      usageMetadata = jsonResponse['usage'];
    }

    return {
      'text': textResponse,
      'images': imagesResponse,
      'usage': usageMetadata,
      'curl': curlCommand,
    };
  }

  @override
  Future<Map<String, dynamic>> generateText(String prompt) async {
    return analyzeImages(prompt, [], []);
  }

  @override
  Future<String> getCurlCommand(
    String prompt,
    List<Uint8List> imageBytesList,
    List<String?> mimeTypes, {
    Map<String, dynamic>? config,
  }) async {
    Map<String, dynamic>? apiConfig;
    if (config != null) {
      apiConfig = Map<String, dynamic>.from(config);
      apiConfig.remove('proxy');
    }

    final bool useImageGeneration = imageBytesList.isEmpty;
    final String url =
        useImageGeneration ? _imageGenerationUrl : _imageEditUrl;
    final String requestBody = useImageGeneration
        ? _prepareImageGenerationBody(prompt, config: apiConfig)
        : _prepareImageEditBody(prompt, imageBytesList, mimeTypes, config: apiConfig);

    final headers = {
      'Authorization': 'Bearer PLACEHOLDER',
      'Content-Type': 'application/json',
    };

    String? proxyToUse = config?['proxy'];

    return CurlGenerator.generate(
      method: 'POST',
      url: url,
      headers: headers,
      body: requestBody,
      proxy: proxyToUse ?? currentProxy,
      headerReplacements: {
        'Authorization': 'Bearer \$(cat assets/xai_api_key.txt)',
      },
    );
  }
}
