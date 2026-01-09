import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImagePreviewList extends StatelessWidget {
  final List<Uint8List> imageBytesList;
  final Function(int) onRemove;

  const ImagePreviewList({
    super.key,
    required this.imageBytesList,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: imageBytesList.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imageBytesList.length,
                itemBuilder: (context, index) => _buildImageItem(context, index),
              ),
            )
          : const Center(
              child: Text(
                'No images selected',
                style: TextStyle(color: Colors.grey),
              ),
            ),
    );
  }

  Widget _buildImageItem(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          InkWell(
            onTap: () => _showImageDialog(context, index),
            child: Image.memory(
              imageBytesList[index],
              fit: BoxFit.cover,
              width: 280,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              onPressed: () => onRemove(index),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBar(
              title: Text('Image ${index + 1}'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.1,
                maxScale: 5.0,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                child: Image.memory(
                  imageBytesList[index],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
