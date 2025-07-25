import 'package:flutter/material.dart';

void disableOverflowErrors() {
  FlutterError.onError = (FlutterErrorDetails details) {
    final exception = details.exception;
    final isOverflowError = exception is FlutterError &&
        !exception.diagnostics.any(
            (e) => e.value.toString().startsWith("A RenderFlex overflowed by"));

    final isNull = exception is FlutterError &&
        exception.diagnostics.any((e) => e.value
            .toString()
            .contains("Null check operator used on a null value"));

    if (isOverflowError || isNull) {
      null;
    } else {
      FlutterError.presentError(details);
    }
  };
}
