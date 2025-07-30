import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io';

// Legacy ErrorHandler - keep for backward compatibility
class LegacyErrorHandler {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 207, 99, 11),
      ),
    );
  }

  static void handleError(BuildContext context, dynamic e) {
    String message;
    
    if (e is SocketException) {
      message = 'No Internet connection.';
    } else if (e is TimeoutException) {
      message = 'Connection timed out. Please try again.';
    } else {
      message = 'Unexpected error occurred. Please try again.';
    }
    
    showError(context, message);
  }
}
