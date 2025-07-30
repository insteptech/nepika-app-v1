import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io';
// Import the new error handler for future use
import 'package:nepika/core/error/error_handler.dart' as new_error_handler;
import 'package:nepika/core/error/failures.dart';

// Legacy ErrorHandler - keep for backward compatibility
class ErrorHandler {
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

  // New method to bridge to the new error handler
  static void handleErrorWithFailure(BuildContext context, Failure failure) {
    final extensions = FailureX(failure);
    showError(context, extensions.userFriendlyMessage);
  }

  // Helper method to convert exceptions to user-friendly messages
  static String getErrorMessage(dynamic error) {
    final failure = new_error_handler.ErrorHandler.handleError(error);
    final extensions = FailureX(failure);
    return extensions.userFriendlyMessage;
  }
}

// Extension wrapper to avoid direct instantiation
class FailureX {
  final Failure failure;
  FailureX(this.failure);
  
  String get userFriendlyMessage {
    if (failure is NetworkFailure) {
      return 'Please check your internet connection and try again.';
    } else if (failure is ServerFailure) {
      return failure.message.isNotEmpty ? failure.message : 'Server error. Please try again later.';
    } else if (failure is AuthFailure) {
      return failure.message.isNotEmpty ? failure.message : 'Authentication failed. Please login again.';
    } else if (failure is ValidationFailure) {
      return failure.message.isNotEmpty ? failure.message : 'Please check your input and try again.';
    } else {
      return failure.message.isNotEmpty ? failure.message : 'Something went wrong. Please try again.';
    }
  }
}
