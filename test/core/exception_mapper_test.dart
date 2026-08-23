import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moment/core/errors/exception_mapper.dart';
import 'package:moment/core/errors/failures.dart';

void main() {
  const mapper = ExceptionMapper();

  test('maps timeouts and sockets to NetworkFailure', () {
    expect(mapper.map(TimeoutException('late')), isA<NetworkFailure>());
    expect(mapper.map(const SocketException('offline')), isA<NetworkFailure>());
  });

  test('maps format errors to ValidationFailure', () {
    expect(mapper.map(const FormatException('bad')), isA<ValidationFailure>());
  });

  test('passes through existing failures', () {
    const original = AuthorizationFailure();
    expect(identical(mapper.map(original), original), isTrue);
  });

  test('maps unknown errors to UnknownFailure without leaking text', () {
    final failure = mapper.map(StateError('raw internals'));
    expect(failure, isA<UnknownFailure>());
    expect(failure.message.contains('raw internals'), isFalse);
  });
}
