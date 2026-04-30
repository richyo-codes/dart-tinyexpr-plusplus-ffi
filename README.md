# tinyexpr_plusplus_ffi

Dart bindings for TinyExpr++ with a small public API for evaluating C-like math
expressions.

This package currently uses `dart:ffi` and a native C-compatible wrapper around
TinyExpr++. The intended direction is to keep the Dart API stable while adding
platform-specific backends:

- native platforms: `dart:ffi` against the compiled TinyExpr++ wrapper
- web: WebAssembly or a compatible pure Dart evaluator

## Current API

```dart
import 'package:tinyexpr_plusplus_ffi/tinyexprpp_fii.dart';

final value = evaluateExpression('1 + 2 * 3');
final error = getLastErrorMessage();
final position = getLastErrorPosition();
```

The package also exposes low-level native bindings such as `tepp_eval`,
`tepp_compile`, `tepp_eval_compiled`, and `tepp_free`. These are implementation
details for most app code. Prefer the friendly Dart functions unless you need
direct access to the native API.

## Native Build

Native builds are handled by `hook/build.dart` using `native_toolchain_c`.

The build hook compiles:

- `src/native/tinyexprpp_wrapper.cpp`
- `src/native/tinyexpr.cpp`

The wrapper exports a C ABI from `src/native/tinyexprpp_wrapper.h`, which keeps
the Dart boundary simple even though the implementation is C++.

## Web Direction

`dart:ffi` is not available to normal Flutter web builds, so web support needs a
different backend. The package should hide that behind the same public API.

Possible web backends:

- compile the C ABI wrapper to WebAssembly and call it through a web-compatible
  FFI/interop layer
- implement a pure Dart evaluator with matching semantics
- start with a pure Dart evaluator and later replace it with WASM if behavior or
  performance requires it

See `docs/platform-backends-plan.md` for the implementation plan.

## Development

Run static analysis:

```sh
dart analyze
```

Run formatting:

```sh
dart format .
```

Regenerate bindings if the native wrapper changes:

```sh
dart run ffigen --config ffigen.yaml
```
