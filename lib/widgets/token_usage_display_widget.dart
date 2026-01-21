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

    return Align(
      alignment: Alignment.centerLeft,
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.data_usage, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Token Usage',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildUsageRow(context, 'Prompt Tokens', usage!['promptTokenCount']),
              _buildUsageRow(context, 'Candidate Tokens', usage!['candidatesTokenCount']),
              const Divider(height: 16),
              _buildUsageRow(context, 'Total Tokens', usage!['totalTokenCount'], isTotal: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageRow(BuildContext context, String label, dynamic value, {bool isTotal = false}) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label, 
              style: TextStyle(
                fontSize: 13,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
               color: isTotal ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}