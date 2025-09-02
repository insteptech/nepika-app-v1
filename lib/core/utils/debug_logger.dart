import 'dart:convert';
import 'package:flutter/foundation.dart';

void logJson(Object? object) {
  const encoder = JsonEncoder.withIndent('  ');

  try {
    final jsonReadyObject = object is Map || object is List
        ? object
        : (object != null &&
              object.runtimeType.toString().contains('Entity') &&
              (object as dynamic).toJson != null)
        ? (object as dynamic).toJson()
        : object;

    final jsonString = encoder.convert(jsonReadyObject);

    debugPrint(jsonString, wrapWidth: 999999);
  } catch (e, stack) {
    debugPrint('logJson: Failed to encode object → $e\n$stack');
  }
}
