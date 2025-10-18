import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UIFeedback {
  static void success(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    _show(context, message, Colors.green);
  }

  static void info(BuildContext context, String message) {
    HapticFeedback.selectionClick();
    _show(context, message, Theme.of(context).colorScheme.primary);
  }

  static void error(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    _show(context, message, Colors.red);
  }

  static void _show(BuildContext context, String message, Color color) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
