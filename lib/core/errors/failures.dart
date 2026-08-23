import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];
}

final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Connection is unavailable right now.',
    super.cause,
  });
}

final class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    super.message = 'Please sign in again.',
    super.cause,
  });
}

final class AuthorizationFailure extends Failure {
  const AuthorizationFailure({
    super.message = 'You do not have access to this.',
    super.cause,
  });
}

final class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Please check what you entered.',
    super.cause,
  });
}

final class StorageFailure extends Failure {
  const StorageFailure({
    super.message = 'We could not save that file.',
    super.cause,
  });
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'Something went wrong while saving.',
    super.cause,
  });
}

final class NotificationFailure extends Failure {
  const NotificationFailure({
    super.message = 'Notifications are unavailable right now.',
    super.cause,
  });
}

final class WidgetFailure extends Failure {
  const WidgetFailure({
    super.message = 'The home widget could not update.',
    super.cause,
  });
}

final class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Something went wrong. Please try again.',
    super.cause,
  });
}
