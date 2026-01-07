import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:flutter/services.dart' show rootBundle;

class GeminiService {
  String? _apiKey;
  http.Client? _httpClient;
  bool _isInit = false;
  
  final String _modelName = 'gemini-2.5-flash-image';

  GeminiService();

  Future<void> _init() async {
    if (_isInit) return;
    
    try {
      final apiKey = await rootBundle.loadString('assets/api_key.txt');
      _apiKey = apiKey.trim();
      
      if (_apiKey!.isEmpty || _apiKey == 'YOUR_API_KEY_HERE') {
        throw Exception('API Key not set in assets/api_key.txt');
      }

      http.Client? httpClient;
      try {
        final proxyData = await rootBundle.loadString('assets/proxy.txt');
        final proxyAddress = proxyData.split('\n').firstWhere(
            (line) => line.trim().isNotEmpty && !line.trim().startsWith('#'),
            orElse: () => '').trim();
        
        if (proxyAddress.isNotEmpty) {
           final client = HttpClient();
           
           var uriStr = proxyAddress;
           if (!uriStr.contains('://')) {
             uriStr = 'socks5://$uriStr';
           }
           
           final uri = Uri.tryParse(uriStr);
           if (uri != null && uri.host.isNotEmpty) {
             final host = uri.host;
             final port = uri.port != 0 && uri.port != -1 ? uri.port : 1080;
             
             String? username;
             String? password;
             
             if (uri.userInfo.isNotEmpty) {
               final authParts = uri.userInfo.split(':');
               username = authParts[0];
               if (authParts.length > 1) {
                 password = authParts[1];
               }
             }

             try {
               final endpoints = await InternetAddress.lookup(host);
               if (endpoints.isNotEmpty) {
                 SocksTCPClient.assignToHttpClient(client, [
                   ProxySettings(endpoints.first, port, password: password, username: username),
                 ]);
                 print('Using SOCKS5 proxy: $host:$port');
               }
             } catch (e) {
               print('Failed to resolve proxy host: $e');
             }
           }

           httpClient = IOClient(client);
        }
      } catch (e) {
        // Proxy file might not exist or be readable, ignore.
        print('Proxy config ignored or empty: $e');
      }

      _httpClient = httpClient;
      _isInit = true;
    } catch (e) {
      // Re-throw or handle initialization errors
      throw Exception('Failed to load API key or config: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeImage(String prompt, Uint8List? imageBytes, String? mimeType) async {
    try {
      await _init();
      
      final client = _httpClient ?? http.Client();
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$_apiKey');
      
      final parts = <Map<String, dynamic>>[
        {'text': prompt}
      ];

      if (imageBytes != null && mimeType != null) {
        parts.add({
          'inline_data': {
            'mime_type': mimeType,
            'data': base64Encode(imageBytes)
          }
        });
      }

      final requestBody = {
        'contents': [
          {
            'parts': parts
          }
        ]
      };

      print('Request Content: Prompt="$prompt", ImageBytes=${imageBytes?.length ?? "null"}, MimeType="${mimeType ?? "null"}"');

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response: ${response.statusCode}');

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
                  print('Part keys: ${part.keys}');
                  if (part.containsKey('text')) {
                    generatedText = (generatedText ?? '') + part['text'];
                  }
                  
                  // Handle both snake_case (API spec) and camelCase (observed in some responses)
                  final inlineData = part['inline_data'] ?? part['inlineData'];
                  if (inlineData != null) {
                    if (inlineData.containsKey('data')) {
                      generatedImage = base64Decode(inlineData['data']);
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
             print('Parsing error: $e');
             return {'text': 'Error parsing response: $e'};
        }
      } else {
        print('Gemini API Error: ${response.statusCode} ${response.body}');
        return {'text': 'Error: API returned ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      return {'text': 'Error: $e'};
    }
  }
}
