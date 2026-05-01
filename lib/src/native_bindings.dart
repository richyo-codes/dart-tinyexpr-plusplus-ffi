import 'dart:ffi' as ffi;

/// Evaluate an expression.
@ffi.Native<ffi.Double Function(ffi.Pointer<ffi.Char>)>()
external double tepp_eval(ffi.Pointer<ffi.Char> expression);

/// Compile an expression.
@ffi.Native<
  ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Int>)
>()
external ffi.Pointer<ffi.Void> tepp_compile(
  ffi.Pointer<ffi.Char> expression,
  ffi.Pointer<ffi.Int> error,
);

/// Evaluate a compiled expression.
@ffi.Native<ffi.Double Function(ffi.Pointer<ffi.Void>)>()
external double tepp_eval_compiled(ffi.Pointer<ffi.Void> compiledExpr);

/// Free a compiled expression.
@ffi.Native<ffi.Void Function(ffi.Pointer<ffi.Void>)>()
external void tepp_free(ffi.Pointer<ffi.Void> compiledExpr);

/// Set a constant variable.
///
/// Passing `nullptr` as [compiledExpr] updates the default evaluator used by
/// [tepp_eval].
@ffi.Native<
  ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Char>, ffi.Double)
>()
external void tepp_set_constant(
  ffi.Pointer<ffi.Void> compiledExpr,
  ffi.Pointer<ffi.Char> name,
  double value,
);

/// Get a constant variable.
///
/// Passing `nullptr` as [compiledExpr] reads from the default evaluator used by
/// [tepp_eval].
@ffi.Native<ffi.Double Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Char>)>()
external double tepp_get_constant(
  ffi.Pointer<ffi.Void> compiledExpr,
  ffi.Pointer<ffi.Char> name,
);

/// Returns the last error message.
@ffi.Native<ffi.Pointer<ffi.Char> Function()>()
external ffi.Pointer<ffi.Char> tepp_get_last_error_message();

/// Returns the last error position.
@ffi.Native<ffi.Int Function()>()
external int tepp_get_last_error_position();
