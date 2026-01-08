import 'package:flutter/material.dart';

class PromptInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const PromptInputWidget({
    super.key,
    required this.controller,
    this.hintText = 'Ask something about the image...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Prompt',
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }
}