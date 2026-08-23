import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/subscription/data/datasources/subscription_remote_data_source.dart';
import 'package:moment/features/subscription/domain/entities/subscription.dart';
import 'package:moment/features/subscription/domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl(this._remote, this._userIdProvider);

  final SubscriptionRemoteDataSource _remote;
  final String? Function() _userIdProvider;

  @override
  Future<Result<MomentPlusOffering>> getOffering() async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.getOffering());
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<CheckoutResult>> requestCheckout(String planId) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.requestCheckout(planId));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }
}
