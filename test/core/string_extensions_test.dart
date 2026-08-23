import 'package:flutter_test/flutter_test.dart';
import 'package:moment/core/extensions/string_extensions.dart';

void main() {
  test('nullIfEmpty trims blank strings', () {
    expect('  '.nullIfEmpty, isNull);
    expect('usha'.nullIfEmpty, 'usha');
  });
}
