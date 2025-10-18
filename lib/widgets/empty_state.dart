import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.asset,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final String? asset;
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (asset != null)
              Image.asset(
                asset!,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            if (title != null) ...[
              const SizedBox(height: 8),
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onSurface.withValues(alpha: 0.65),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
