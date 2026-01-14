import 'package:flutter/material.dart';

class ErrorSnackbar {
  /// Shows an error snackbar with standard styling
  static void showError(
    BuildContext context, {
    required String message,
    String dismissLabel = 'Dismiss',
    Color backgroundColor = Colors.red,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 5),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: SnackBarAction(
          label: dismissLabel,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          textColor: textColor,
        ),
      ),
    );
  }

  /// Creates a pre-configured SnackBar widget for errors
  static SnackBar createErrorSnackbar({
    required String message,
    String dismissLabel = 'Dismiss',
    Color backgroundColor = Colors.red,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 5),
  }) {
    return SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration,
      action: SnackBarAction(
        label: dismissLabel,
        onPressed: () {},
        textColor: textColor,
      ),
    );
  }
}