import 'package:flutter/material.dart';

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

  void _updateConfig() {
    final Map<String, dynamic> config = {};
    if (_aspectRatioController.text.trim().isNotEmpty) {
      config['aspectRatio'] = _aspectRatioController.text.trim();
    }
    if (_imageSizeController.text.trim().isNotEmpty) {
      config['imageSize'] = _imageSizeController.text.trim();
    }
    widget.onConfigChanged(config);
  }

  @override
  void initState() {
    super.initState();
    // Notify initial config
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateConfig());
  }

  @override
  void dispose() {
    _aspectRatioController.dispose();
    _imageSizeController.dispose();
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
                    controller: _imageSizeController,
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
          ],
        ),
      ),
    );
  }
}
