@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:tinyexpr_plusplus_ffi/tinyexpr_plusplus_ffi.dart';

void main() {
  setUpAll(() async {
    await initializeTinyExpr(
      moduleUrl: './packages/tinyexpr_plusplus_ffi/tinyexprpp_loader.js',
    );
  });

  test('evaluates arithmetic through the web backend', () {
    expect(evaluateExpression('1+2*3'), 7);
    expect(evaluateExpression('(10-4)/3'), 2);
  });

  test('evaluates math functions through the web backend', () {
    expect(evaluateExpression('sqrt(144)'), 12);
    expect(evaluateExpression('sin(0)'), closeTo(0, 0.0000001));
  });

  test('returns NaN for invalid expressions from the web backend', () {
    final result = evaluateExpression('1+');

    expect(result.isNaN, isTrue);
  });
}
