import 'package:flutter/material.dart';
import 'dart:io';

class GenerationConfigWidget extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onConfigChanged;

  const GenerationConfigWidget({
    super.key,
    required this.onConfigChanged,
  });

  @override
  State<GenerationConfigWidget> createState() => _GenerationConfigWidgetState();
}

class _GenerationConfigWidgetState extends State<GenerationConfigWidget> {
  final TextEditingController _aspectRatioController = TextEditingController(text: '');
  final TextEditingController _imageSizeController = TextEditingController(text: '');
  final TextEditingController _proxyController = TextEditingController(text: '');

  void _updateConfig() {
    final Map<String, dynamic> config = {};
    if (_aspectRatioController.text.trim().isNotEmpty) {
      config['aspectRatio'] = _aspectRatioController.text.trim();
    }
    if (_imageSizeController.text.trim().isNotEmpty) {
      config['imageSize'] = _imageSizeController.text.trim();
    }
    if (_proxyController.text.trim().isNotEmpty) {
      config['proxy'] = _proxyController.text.trim();
    }
    widget.onConfigChanged(config);
  }

  @override
  void initState() {
    super.initState();
    _loadProxy();
    // Notify initial config
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateConfig());
  }

  Future<void> _loadProxy() async {
    try {
      final file = File('assets/proxy.txt');
      if (await file.exists()) {
        final content = await file.readAsString();
        final proxy = content.split('\n').firstWhere(
              (line) => line.trim().isNotEmpty && !line.trim().startsWith('#'),
              orElse: () => '',
            ).trim();
        if (proxy.isNotEmpty) {
          if (mounted) {
            setState(() {
              _proxyController.text = proxy;
            });
            _updateConfig();
          }
        }
      }
    } catch (e) {
      // Ignore error
    }
  }

  @override
  void dispose() {
    _aspectRatioController.dispose();
    _imageSizeController.dispose();
    _proxyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generation Config', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _aspectRatioController,
                    decoration: const InputDecoration(
                      labelText: 'Aspect Ratio',
                      hintText: 'e.g. 16:9',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      isDense: true,
                    ),
                    onChanged: (val) => _updateConfig(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _imageSizeController, // Fixed variable
                    decoration: const InputDecoration(
                      labelText: 'Image Size',
                      hintText: 'e.g. 1k 2k 4k',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      isDense: true,
                    ),
                    onChanged: (val) => _updateConfig(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _proxyController,
              decoration: const InputDecoration(
                labelText: 'Proxy',
                hintText: 'e.g. 127.0.0.1:7890',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                isDense: true,
              ),
              onChanged: (val) => _updateConfig(),
            ),
          ],
        ),
      ),
    );
  }
}
