import 'package:flutter/material.dart';

/// A helper function to show a SnackBar with a consistent style and duration.
///
/// [context]: The BuildContext from which to find the ScaffoldMessenger.
/// [message]: The text content of the SnackBar.
/// [isError]: Determines the background color of the SnackBar. Defaults to `false`.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  // Ensure the context is still valid before trying to show a SnackBar.
  if (!context.mounted) return;

  // Hide any currently displayed SnackBar to avoid queuing.
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  // Show the new SnackBar.
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(milliseconds: 500),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}