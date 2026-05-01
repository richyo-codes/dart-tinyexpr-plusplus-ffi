import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'tinyexpr_backend.dart';

final TinyExprBackend backend = WebTinyExprBackend();

class WebTinyExprBackend implements TinyExprBackend {
  static const _loaderUrl =
      'packages/tinyexpr_plusplus_ffi/tinyexprpp_loader.js';

  _TinyExprWasmModule? _module;
  Future<void>? _initializing;

  @override
  Future<void> initialize({String? moduleUrl, String? wasmUrl}) {
    final existingModule = _module;
    if (existingModule != null) {
      return Future.value();
    }

    return _initializing ??= _load(moduleUrl: moduleUrl, wasmUrl: wasmUrl);
  }

  Future<void> _load({String? moduleUrl, String? wasmUrl}) async {
    final loader = _TinyExprWasmLoader(
      await importModule((moduleUrl ?? _loaderUrl).toJS).toDart,
    );
    final options = JSObject();
    if (wasmUrl != null) {
      options['wasmUrl'] = wasmUrl.toJS;
    }
    _module = await loader.initializeTinyExpr(options).toDart;
  }

  @override
  double evaluate(String expression) {
    final module = _requireModule();
    final expressionPtr = _writeString(module, expression);
    try {
      return module.teppEval(expressionPtr);
    } catch (_) {
      return double.nan;
    } finally {
      module.free(expressionPtr);
    }
  }

  @override
  String get lastErrorMessage {
    final module = _module;
    if (module == null) {
      return '';
    }

    final ptr = module.teppGetLastErrorMessage();
    return ptr == 0 ? '' : module.utf8ToString(ptr);
  }

  @override
  int get lastErrorPosition {
    final module = _module;
    if (module == null) {
      return -1;
    }
    return module.teppGetLastErrorPosition();
  }

  @override
  void setCustomVariable(String name, double value) {
    final module = _requireModule();
    final namePtr = _writeString(module, name);
    try {
      module.teppSetConstant(0, namePtr, value);
    } finally {
      module.free(namePtr);
    }
  }

  _TinyExprWasmModule _requireModule() {
    final module = _module;
    if (module == null) {
      throw StateError(
        'TinyExpr++ web backend is not initialized. '
        'Call and await initializeTinyExpr() before using it.',
      );
    }
    return module;
  }

  int _writeString(_TinyExprWasmModule module, String value) {
    final bytes = utf8.encode(value);
    final ptr = module.malloc(bytes.length + 1);
    final heap = module.heapU8.toDart;
    heap.setRange(ptr, ptr + bytes.length, bytes);
    heap[ptr + bytes.length] = 0;
    return ptr;
  }
}

extension type _TinyExprWasmLoader(JSObject _) implements JSObject {
  external JSPromise<_TinyExprWasmModule> initializeTinyExpr(JSObject options);
}

extension type _TinyExprWasmModule(JSObject _) implements JSObject {
  @JS('_malloc')
  external int malloc(int size);

  @JS('_free')
  external void free(int ptr);

  @JS('_tepp_eval')
  external double teppEval(int expressionPtr);

  @JS('_tepp_get_last_error_message')
  external int teppGetLastErrorMessage();

  @JS('_tepp_get_last_error_position')
  external int teppGetLastErrorPosition();

  @JS('_tepp_set_constant')
  external void teppSetConstant(int compiledExprPtr, int namePtr, double value);

  @JS('UTF8ToString')
  external String utf8ToString(int ptr);

  @JS('HEAPU8')
  external JSUint8Array get heapU8;
}
