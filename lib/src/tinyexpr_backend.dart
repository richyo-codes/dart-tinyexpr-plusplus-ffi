abstract interface class TinyExprBackend {
  Future<void> initialize({String? moduleUrl, String? wasmUrl});

  double evaluate(String expression);

  String get lastErrorMessage;

  int get lastErrorPosition;

  void setCustomVariable(String name, double value);
}
