import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

void logJson(Object? object) {
  const encoder = JsonEncoder.withIndent('  ');

  try {
    final jsonReadyObject = _convertToJsonSafe(object);
    final jsonString = encoder.convert(jsonReadyObject);
    debugPrint(jsonString, wrapWidth: 999999);
  } catch (e) {
    debugPrint('logJson: Failed to encode object → Converting object to an encodable object failed: $object');
    debugPrint('Error details: $e');
    
    // Try to provide a meaningful fallback
    if (object != null) {
      debugPrint('Object type: ${object.runtimeType}');
      debugPrint('Object string: ${object.toString()}');
    }
  }
}

/// Convert any object to a JSON-safe format
Object? _convertToJsonSafe(Object? object) {
  if (object == null) return null;
  
  // Handle primitive types
  if (object is String || object is num || object is bool) {
    return object;
  }
  
  // Handle collections
  if (object is Map) {
    return object.map((key, value) => MapEntry(
      key.toString(), 
      _convertToJsonSafe(value)
    ));
  }
  
  if (object is List) {
    return object.map((item) => _convertToJsonSafe(item)).toList();
  }
  
  // Handle exceptions specially
  if (object is Exception) {
    return {
      'type': object.runtimeType.toString(),
      'message': object.toString(),
      'details': _extractExceptionDetails(object),
    };
  }
  
  // Handle entities with toJson method
  if (object.runtimeType.toString().contains('Entity')) {
    try {
      final dynamic obj = object;
      if (obj.toJson != null) {
        return obj.toJson();
      }
    } catch (e) {
      // Fall through to default handling
    }
  }
  
  // Default: convert to string representation
  return {
    'type': object.runtimeType.toString(),
    'value': object.toString(),
  };
}

/// Extract useful details from different exception types
Map<String, dynamic> _extractExceptionDetails(Exception exception) {
  final details = <String, dynamic>{};
  
  if (exception is TimeoutException) {
    details['timeout'] = exception.duration?.toString();
    details['message'] = exception.message ?? 'Request timed out';
  } else if (exception is FormatException) {
    details['source'] = exception.source;
    details['offset'] = exception.offset;
  } else if (exception is ArgumentError) {
    final argError = exception as ArgumentError;
    details['invalidValue'] = argError.invalidValue?.toString();
    details['name'] = argError.name;
  }
  
  return details;
}
