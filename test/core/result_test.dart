import 'package:flutter_test/flutter_test.dart';
import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';

void main() {
  group('Result', () {
    test('Success exposes value and hides failure', () {
      const result = Success<int>(7);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 7);
      expect(result.failureOrNull, isNull);
      expect(result.when(success: (value) => value, failure: (_) => -1), 7);
    });

    test('Failed exposes typed failure', () {
      const result = Failed<int>(NetworkFailure());

      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('map transforms success and preserves failure', () {
      const ok = Success<int>(2);
      const failed = Failed<int>(ValidationFailure());

      expect(ok.map((value) => value * 3).valueOrNull, 6);
      expect(
        failed.map((value) => value * 3).failureOrNull,
        isA<ValidationFailure>(),
      );
    });
  });
}
