import 'src/tinyexpr_backend_stub.dart'
    if (dart.library.ffi) 'src/tinyexpr_backend_native.dart'
    if (dart.library.js_interop) 'src/tinyexpr_backend_web.dart';

/// Initializes the active TinyExpr++ backend.
///
/// Native platforms complete immediately. Web loads the Emscripten JS/WASM
/// module and must be awaited before using the synchronous evaluation API.
Future<void> initializeTinyExpr({String? moduleUrl, String? wasmUrl}) =>
    backend.initialize(moduleUrl: moduleUrl, wasmUrl: wasmUrl);

double evaluateExpression(String expression) => backend.evaluate(expression);

String getLastErrorMessage() => backend.lastErrorMessage;

int getLastErrorPosition() => backend.lastErrorPosition;

void setCustomVariable(String name, double value) =>
    backend.setCustomVariable(name, value);
