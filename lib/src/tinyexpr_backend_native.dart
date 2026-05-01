import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

import 'native_bindings.dart' as native;
import 'tinyexpr_backend.dart';

final TinyExprBackend backend = NativeTinyExprBackend();

class NativeTinyExprBackend implements TinyExprBackend {
  @override
  Future<void> initialize({String? moduleUrl, String? wasmUrl}) async {}

  @override
  double evaluate(String expression) {
    final expressionPtr = expression.toNativeUtf8().cast<ffi.Char>();
    try {
      return native.tepp_eval(expressionPtr);
    } catch (_) {
      return double.nan;
    } finally {
      calloc.free(expressionPtr);
    }
  }

  @override
  String get lastErrorMessage {
    final ptr = native.tepp_get_last_error_message().cast<Utf8>();
    return ptr == ffi.nullptr ? '' : ptr.toDartString();
  }

  @override
  int get lastErrorPosition => native.tepp_get_last_error_position();

  @override
  void setCustomVariable(String name, double value) {
    final namePtr = name.toNativeUtf8().cast<ffi.Char>();
    try {
      native.tepp_set_constant(ffi.nullptr, namePtr, value);
    } finally {
      calloc.free(namePtr);
    }
  }
}
