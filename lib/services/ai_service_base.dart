import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:meta/meta.dart';
import 'ai_model_interface.dart';

/// Base class for AI services that provides common functionality
abstract class AIServiceBase implements AIModelInterface {
  String? _apiKey;
  http.Client? _httpClient;
  String? _currentProxy;
  bool _isInitialized = false;
  String? saveDirectory;

  AIServiceBase({this.saveDirectory});

  /// Configure HTTP client with proxy
  Future<http.Client?> _configureProxyClient(String proxyAddress) async {
    if (proxyAddress.isEmpty) return null;

    try {
      final ioClient = HttpClient();

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
            SocksTCPClient.assignToHttpClient(ioClient, [
              ProxySettings(endpoints.first, port, password: password, username: username),
            ]);
            return IOClient(ioClient);
          }
        } catch (e) {
          // Handle lookup error
          print('Proxy lookup failed: $e');
        }
      }
    } catch (e) {
      print('Proxy configuration failed: $e');
    }
    return null;
  }

  /// Update the client with a specific proxy
  @protected
  Future<void> updateClientProxy(String? proxy) async {
    if (proxy == _currentProxy) return;
    
    _currentProxy = proxy;
    if (proxy == null || proxy.isEmpty) {
      _httpClient = null; // Will use default http.Client()
    } else {
      _httpClient = await _configureProxyClient(proxy);
    }
  }

  /// Load API key and setup HTTP client (with proxy if needed)
  Future<void> _setupClient() async {
    if (_isInitialized) return;

    try {
      // Load API key from assets
      final apiKey = await rootBundle.loadString('assets/api_key.txt');
      _apiKey = apiKey.trim();

      if (_apiKey!.isEmpty || _apiKey == 'YOUR_API_KEY_HERE') {
        throw Exception('API Key not set in assets/api_key.txt');
      }

      try {
        // Try to load proxy configuration
        final proxyData = await rootBundle.loadString('assets/proxy.txt');
        final proxyAddress = proxyData.split('\n').firstWhere(
            (line) => line.trim().isNotEmpty && !line.trim().startsWith('#'),
            orElse: () => '').trim();
            
        await updateClientProxy(proxyAddress);
      } catch (e) {
        // Proxy file might not exist or be readable, ignore.
      }

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize $platform service: $e');
    }
  }

  @override
  Future<void> initialize() async {
    await _setupClient();
  }

  /// Get the HTTP client (with or without proxy)
  http.Client get httpClient => _httpClient ?? http.Client();

  /// Get the API key after initialization
  String? get apiKey {
    if (!_isInitialized) {
      throw Exception('Service not initialized. Call initialize() first.');
    }
    return _apiKey;
  }

  /// Save generated image to device - internal method for use by subclasses
  @protected
  Future<void> saveGeneratedImage(Uint8List imageBytes) async {
    if (saveDirectory == null) return;

    try {
      String dirPath;
      String? home;
      if (saveDirectory != null && saveDirectory!.startsWith('~/') && (home = Platform.environment['HOME']) != null) {
        // Ensure both values are non-null before calling replaceFirst
        String actualSaveDir = saveDirectory!;
        String actualHome = home!; // Non-null because the condition checks for home != null
        dirPath = actualSaveDir.replaceFirst('~', actualHome);
      } else if (saveDirectory != null){
        dirPath = saveDirectory!;
      } else {
        // Fallback to default directory if saveDirectory is null
        home = Platform.environment['HOME'] ?? Platform.environment['UserProfile'];
        if (home != null) {
          dirPath = '$home/Pictures/ai';
        } else {
          // Silently fail if home directory cannot be determined
          return;
        }
      }

      final directory = Directory(dirPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$dirPath/${platform.toLowerCase()}_gen_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
    } catch (e) {
      // Silently handle save errors
    }
  }

}