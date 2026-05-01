import 'tinyexpr_backend.dart';

final TinyExprBackend backend = _UnsupportedTinyExprBackend();

class _UnsupportedTinyExprBackend implements TinyExprBackend {
  @override
  Future<void> initialize({String? moduleUrl, String? wasmUrl}) async {
    throw UnsupportedError('TinyExpr++ is not supported on this platform');
  }

  @override
  double evaluate(String expression) {
    throw UnsupportedError('TinyExpr++ is not supported on this platform');
  }

  @override
  String get lastErrorMessage => '';

  @override
  int get lastErrorPosition => -1;

  @override
  void setCustomVariable(String name, double value) {
    throw UnsupportedError('TinyExpr++ is not supported on this platform');
  }
}
