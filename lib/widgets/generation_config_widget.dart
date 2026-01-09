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
  String _aspectRatio = '16:9';
  String _imageSize = '2K';

  final List<String> _aspectRatios = ['16:9', '4:3', '1:1', '3:4', '9:16'];
  final List<String> _imageSizes = ['2K']; 

  void _updateConfig() {
    widget.onConfigChanged({
      'aspectRatio': _aspectRatio,
      'imageSize': _imageSize,
    });
  }

  @override
  void initState() {
    super.initState();
    // Notify initial config
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateConfig());
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
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Aspect Ratio',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      isDense: true,
                    ),
                    value: _aspectRatio,
                    items: _aspectRatios.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _aspectRatio = val);
                        _updateConfig();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Image Size',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      isDense: true,
                    ),
                    value: _imageSize,
                    items: _imageSizes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _imageSize = val);
                        _updateConfig();
                      }
                    },
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
