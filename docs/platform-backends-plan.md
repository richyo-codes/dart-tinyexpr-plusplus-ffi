# Platform Backends Plan

## Goal

Make `tinyexpr_plusplus_ffi` usable from Flutter web without forcing app code to
know whether expression evaluation is native FFI, WebAssembly, or pure Dart.

The public package API should remain stable:

```dart
double evaluateExpression(String expression);
String getLastErrorMessage();
int getLastErrorPosition();
void setCustomVariable(String name, double value);
```

Native-only raw bindings can remain available behind an explicit native library
file, but normal consumers should not import `dart:ffi` directly.

## Current State

`lib/tinyexprpp_fii.dart` currently imports `dart:ffi` directly and exposes both:

- friendly Dart helpers, such as `evaluateExpression`
- raw native symbols, such as `tepp_eval` and `tepp_compile`

Native code is built through `hook/build.dart` with `native_toolchain_c`.

This works for desktop and mobile native targets, but it prevents Flutter web
from compiling because `dart:ffi` is not available there.

## Target Design

Split the package into a stable public facade and platform-specific backends.

Suggested file layout:

```text
lib/
  tinyexpr_plusplus_ffi.dart
  src/
    tinyexpr_backend.dart
    tinyexpr_backend_stub.dart
    tinyexpr_backend_native.dart
    tinyexpr_backend_web.dart
    native_bindings.dart
    web_wasm_bindings.dart
```

Facade:

```dart
import 'src/tinyexpr_backend_stub.dart'
    if (dart.library.ffi) 'src/tinyexpr_backend_native.dart'
    if (dart.library.js_interop) 'src/tinyexpr_backend_web.dart';

double evaluateExpression(String expression) => backend.evaluate(expression);
String getLastErrorMessage() => backend.lastErrorMessage;
int getLastErrorPosition() => backend.lastErrorPosition;
```

Backend interface:

```dart
abstract interface class TinyExprBackend {
  double evaluate(String expression);
  String get lastErrorMessage;
  int get lastErrorPosition;
  void setCustomVariable(String name, double value);
}
```

## Native Backend

Move the current `dart:ffi` bindings into `src/native_bindings.dart` and wrap
them with `NativeTinyExprBackend`.

Keep the current C ABI:

- `tepp_eval`
- `tepp_compile`
- `tepp_eval_compiled`
- `tepp_free`
- `tepp_set_constant`
- `tepp_get_constant`
- `tepp_get_last_error_message`
- `tepp_get_last_error_position`

Implementation notes:

- Keep `hook/build.dart` as the native build path.
- Fix ownership bugs while moving code. `setCustomVariable` currently allocates
  both `exprPtr` and `namePtr`, but only frees `namePtr`.
- Avoid exposing `print` in library error paths. Store native errors and return
  `double.nan` consistently.

## Web Backend Options

### Option A: WebAssembly TinyExpr++ Backend

Compile the existing C ABI wrapper to WASM with Emscripten.

Expected artifacts:

```text
web/
  tinyexprpp.js
  tinyexprpp.wasm
```

Requirements:

- export `_tepp_eval`
- export `_tepp_get_last_error_message`
- export `_tepp_get_last_error_position`
- export `_tepp_set_constant` if variables are supported
- export `_malloc` and `_free` for string interop

Candidate compile shape:

```sh
emcc src/native/tinyexprpp_wrapper.cpp src/native/tinyexpr.cpp \
  -std=c++20 \
  -DTE_BITWISE_OPERATORS=1 \
  -sMODULARIZE=1 \
  -sEXPORT_ES6=1 \
  -sENVIRONMENT=web \
  -sEXPORTED_FUNCTIONS='["_malloc","_free","_tepp_eval","_tepp_get_last_error_message","_tepp_get_last_error_position"]' \
  -sEXPORTED_RUNTIME_METHODS='["UTF8ToString","stringToUTF8","lengthBytesUTF8"]' \
  -o tinyexprpp.js
```

Pros:

- closest behavior to native
- one expression engine across platforms
- supports the `CalcCompiler` direction later if the native side grows

Cons:

- async initialization
- bundling and loading JS/WASM inside Flutter web needs care
- generated bindings will differ from native FFI bindings

### Option B: Pure Dart Web Backend

Implement a compatible evaluator in Dart for web.

Pros:

- easiest Flutter web integration
- no WASM loader
- no Emscripten toolchain in CI

Cons:

- semantic drift from TinyExpr++
- parser, precedence, numeric behavior, and error messages become duplicated

### Recommendation

Start with the facade and native backend split first. Then implement the web
backend behind the same interface.

Use a pure Dart backend only if it can match the required expression subset
quickly. Otherwise, prefer the WASM backend because this package already owns a
C ABI wrapper that is suitable for WebAssembly exports.

## Migration Steps

1. Add `lib/tinyexpr_plusplus_ffi.dart` as the stable public entrypoint.
2. Move current FFI symbols into `lib/src/native_bindings.dart`.
3. Add `TinyExprBackend` and `NativeTinyExprBackend`.
4. Keep `lib/tinyexprpp_fii.dart` as a compatibility export for existing apps.
5. Add `tinyexpr_backend_web.dart` as a stub that throws
   `UnsupportedError('Web backend is not implemented yet')`.
6. Add tests against the public facade:
   - arithmetic precedence
   - bitwise operators
   - invalid expression error message
   - custom variable behavior
7. Add a web backend:
   - WASM first if Emscripten is acceptable in CI
   - pure Dart first if fast boot and simpler packaging matter more
8. Add web tests that exercise the same public API.

## Compatibility Rules

- App code should import only `package:tinyexpr_plusplus_ffi/tinyexpr_plusplus_ffi.dart`.
- Existing import path `tinyexprpp_fii.dart` should remain available during the
  migration.
- Raw FFI symbols should not be part of the cross-platform API.
- Web initialization must be explicit if the backend is asynchronous.

Potential async API:

```dart
Future<void> initializeTinyExpr();
```

For native this can complete immediately. For WASM it can load the module.

## CI Work

Add jobs for:

- `dart analyze`
- VM tests for native facade
- web compilation smoke test
- optional Emscripten build if the WASM backend is selected

The consuming Flutter app should not need conditional imports after this package
owns platform selection.
