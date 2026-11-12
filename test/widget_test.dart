import 'package:flutter_test/flutter_test.dart';
import 'package:orlogo_zarlaga/theme.dart';

void main() {
  test('money formats with thousands separator', () {
    expect(money(2548), '\$ 2,548.00');
  });
}
