import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/services.dart' show rootBundle;

class GeminiService {
  GenerativeModel? _model;
  bool _isInit = false;

  GeminiService();

  Future<void> _init() async {
    if (_isInit) return;
    
    try {
      final apiKey = await rootBundle.loadString('assets/api_key.txt');
      final cleanedKey = apiKey.trim();
      
      if (cleanedKey.isEmpty || cleanedKey == 'YOUR_API_KEY_HERE') {
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
           // Remove protocol if present (socks5://)
           var hostPort = proxyAddress;
           if (hostPort.contains('://')) {
             hostPort = hostPort.split('://').last;
           }

           client.findProxy = (uri) {
             return "SOCKS5 $hostPort; DIRECT";
           };
           httpClient = IOClient(client);
           print('Using SOCKS5 proxy: $hostPort');
        }
      } catch (e) {
        // Proxy file might not exist or be readable, ignore.
        print('Proxy config ignored or empty: $e');
      }

      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: cleanedKey,
        httpClient: httpClient,
      );
      _isInit = true;
    } catch (e) {
      // Re-throw or handle initialization errors
      throw Exception('Failed to load API key or config: $e');
    }
  }

  Future<String?> analyzeImage(String prompt, Uint8List imageBytes, String mimeType) async {
    try {
      await _init();
      if (_model == null) {
        return 'Error: Gemini model could not be initialized.';
      }

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];

      final response = await _model!.generateContent(content);
      return response.text;
    } catch (e) {
      return 'Error: $e';
    }
  }
}
