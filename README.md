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
import 'package:tinyexpr_plusplus_ffi/tinyexpr_plusplus_ffi.dart';

final value = evaluateExpression('1 + 2 * 3');
final error = getLastErrorMessage();
final position = getLastErrorPosition();
```

The old `tinyexprpp_fii.dart` import path remains available as a compatibility
export. Low-level native bindings such as `tepp_eval`, `tepp_compile`,
`tepp_eval_compiled`, and `tepp_free` are now kept in
`src/native_bindings.dart` and should be treated as native-only implementation
details.

## Native Build

Native builds are handled by `hook/build.dart` using `native_toolchain_c`.

The build hook compiles:

- `src/native/tinyexprpp_wrapper.cpp`
- `src/native/tinyexpr.cpp`

The wrapper exports a C ABI from `src/native/tinyexprpp_wrapper.h`, which keeps
the Dart boundary simple even though the implementation is C++.

## Web Backend

`dart:ffi` is not available to normal Flutter web builds, so the public facade
uses a WebAssembly backend on web. Web apps must initialize it before calling the
synchronous API:

```dart
await initializeTinyExpr();

final value = evaluateExpression('2 + 2');
```

Build the Emscripten artifacts with:

```sh
tool/build_wasm.sh
```

The script emits `lib/tinyexprpp.js`, `lib/tinyexprpp.wasm`, and copies the same
runtime artifacts to `web/`. If a consuming web app serves the loader or WASM
from a custom location, pass explicit URLs:

```dart
await initializeTinyExpr(
  moduleUrl: 'tinyexprpp_loader.js',
  wasmUrl: 'tinyexprpp.wasm',
);
```

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

## Credits

- https://github.com/Blake-Madden/tinyexpr-plusplus
- https://github.com/codeplea/tinyexpr
