import 'package:moment/core/errors/failures.dart';
import 'package:moment/features/subscription/domain/entities/subscription.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<MomentPlusOffering> getOffering() async {
    final data = await _client.rpc<Map<String, dynamic>>(
      'get_moment_plus_offering',
    );
    return _mapOffering(data);
  }

  Future<CheckoutResult> requestCheckout(String planId) async {
    final data = await _client.rpc<Map<String, dynamic>>(
      'request_moment_plus_checkout',
      params: {'p_plan_id': planId},
    );
    return CheckoutResult(
      status: data['status'] as String? ?? 'pending',
      message: data['message'] as String? ?? 'Checkout unavailable.',
      planId: data['plan_id'] as String?,
    );
  }

  MomentPlusOffering _mapOffering(Map<String, dynamic> data) {
    final plansJson = data['plans'] as List? ?? [];
    final plans = plansJson.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return SubscriptionPlan(
        id: map['id'] as String,
        displayName: map['display_name'] as String,
        priceCents: map['price_cents'] as int,
        currency: map['currency'] as String? ?? 'INR',
        interval: SubscriptionPlan.intervalFromValue(
          map['billing_interval'] as String? ?? 'month',
        ),
      );
    }).toList();

    UserSubscription? subscription;
    final subJson = data['subscription'];
    if (subJson is Map) {
      final map = Map<String, dynamic>.from(subJson);
      subscription = UserSubscription(
        planId: map['plan_id'] as String,
        status: map['status'] as String,
        expiresAt: map['expires_at'] == null
            ? null
            : DateTime.parse(map['expires_at'] as String),
      );
    }

    final entitlements = (data['entitlements'] as List? ?? [])
        .map((item) => item as String)
        .toList();

    final limitsMap = Map<String, dynamic>.from((data['limits'] as Map?) ?? {});

    final features = (data['features'] as List? ?? [])
        .map((item) => item as String)
        .toList();

    return MomentPlusOffering(
      plans: plans,
      features: features,
      limits: MomentPlusLimits(
        freeMemoryLimit: limitsMap['free_memory_limit'] as int? ?? 3,
        memoryCount: limitsMap['memory_count'] as int? ?? 0,
      ),
      subscription: subscription,
      entitlements: entitlements,
    );
  }

  Failure mapError(Object error) {
    if (error is PostgrestException) {
      return DatabaseFailure(cause: error);
    }
    if (error is Failure) return error;
    return UnknownFailure(cause: error);
  }
}
