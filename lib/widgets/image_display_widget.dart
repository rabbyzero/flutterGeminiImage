import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageDisplayWidget extends StatelessWidget {
  final List<Uint8List> imageBytesList;
  final List<XFile> images;
  final Function(int) onImageTap;
  final Function(int) onRemoveImage;

  const ImageDisplayWidget({
    super.key,
    required this.imageBytesList,
    required this.images,
    required this.onImageTap,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    if (imageBytesList.isEmpty) {
      return const Center(
        child: Text(
          'No images selected',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageBytesList.length,
        itemBuilder: (context, index) {
          return _buildSingleImageItem(index);
        },
      ),
    );
  }

  // Method to build a single image item with controls
  Widget _buildSingleImageItem(int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          InkWell(
            onTap: () => onImageTap(index),
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
              onPressed: () => onRemoveImage(index),
            ),
          ),
        ],
      ),
    );
  }
}