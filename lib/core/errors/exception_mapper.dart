import 'dart:async';

import 'package:moment/core/errors/failures.dart';

class ExceptionMapper {
  const ExceptionMapper();

  static const _networkTypeNames = {
    'SocketException',
    'HandshakeException',
    'HttpException',
    'ClientException',
  };

  Failure map(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) {
      return error;
    }
    if (error is TimeoutException ||
        _networkTypeNames.contains(error.runtimeType.toString())) {
      return NetworkFailure(cause: error);
    }
    if (error is FormatException || error is ArgumentError) {
      return ValidationFailure(cause: error);
    }
    return UnknownFailure(cause: error);
  }
}
