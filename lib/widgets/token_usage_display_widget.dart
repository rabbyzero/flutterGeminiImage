import 'package:flutter/material.dart';

class TokenUsageDisplayWidget extends StatelessWidget {
  final Map<String, dynamic>? usage;

  const TokenUsageDisplayWidget({
    super.key,
    this.usage,
  });

  @override
  Widget build(BuildContext context) {
    if (usage == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Token Usage',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildUsageRow('Prompt Tokens', usage!['promptTokenCount']),
        _buildUsageRow('Candidate Tokens', usage!['candidatesTokenCount']),
        _buildUsageRow('Total Tokens', usage!['totalTokenCount']),
      ],
    );
  }

  Widget _buildUsageRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value.toString()),
        ],
      ),
    );
  }
}