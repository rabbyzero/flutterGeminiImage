import 'package:flutter/material.dart';
import '../models/model_manager.dart';

class ModelSelectorWidget extends StatelessWidget {
  final ModelManager modelManager;
  final Function(String platform, String model)? onModelSelected;

  const ModelSelectorWidget({
    super.key,
    required this.modelManager,
    this.onModelSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.model_training),
      tooltip: 'Select AI Model',
      onSelected: (String modelKey) {
        final parts = modelKey.split('_');
        if (parts.length >= 2) {
          final platform = parts[0];
          final model = parts.sublist(1).join('_');
          onModelSelected?.call(platform, model);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Active model: $platform $model')),
          );
        }
      },
      itemBuilder: (BuildContext context) {
        return modelManager.allModels.map((model) {
          final modelKey = '${model.platform}_${model.modelName}';
          final isSelected = modelManager.activeModel == model;
          return CheckedPopupMenuItem<String>(
            value: modelKey,
            checked: isSelected,
            child: Text('${model.platform} - ${model.modelName}'),
          );
        }).toList();
      },
    );
  }
}