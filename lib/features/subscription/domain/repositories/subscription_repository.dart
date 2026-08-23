import 'package:moment/core/result/result.dart';
import 'package:moment/features/subscription/domain/entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<Result<MomentPlusOffering>> getOffering();

  Future<Result<CheckoutResult>> requestCheckout(String planId);
}
