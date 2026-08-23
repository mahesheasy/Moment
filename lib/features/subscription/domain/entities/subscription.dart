import 'package:equatable/equatable.dart';

enum BillingInterval { month, year }

class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.id,
    required this.displayName,
    required this.priceCents,
    required this.currency,
    required this.interval,
  });

  final String id;
  final String displayName;
  final int priceCents;
  final String currency;
  final BillingInterval interval;

  String get formattedPrice {
    final major = priceCents / 100;
    if (currency == 'INR') {
      final whole = major == major.roundToDouble();
      return whole ? '₹${major.toInt()}' : '₹${major.toStringAsFixed(2)}';
    }
    return '$currency ${major.toStringAsFixed(2)}';
  }

  String get intervalLabel => switch (interval) {
    BillingInterval.month => '/month',
    BillingInterval.year => '/year',
  };

  static BillingInterval intervalFromValue(String value) {
    return switch (value) {
      'year' => BillingInterval.year,
      _ => BillingInterval.month,
    };
  }

  @override
  List<Object?> get props => [id, displayName, priceCents, currency, interval];
}

class UserSubscription extends Equatable {
  const UserSubscription({
    required this.planId,
    required this.status,
    this.expiresAt,
  });

  final String planId;
  final String status;
  final DateTime? expiresAt;

  bool get isActive => status == 'active' || status == 'trialing';

  @override
  List<Object?> get props => [planId, status, expiresAt];
}

class MomentPlusLimits extends Equatable {
  const MomentPlusLimits({
    required this.freeMemoryLimit,
    required this.memoryCount,
  });

  final int freeMemoryLimit;
  final int memoryCount;

  bool canCreateMemory({required bool isPremium}) {
    if (isPremium) return true;
    return memoryCount < freeMemoryLimit;
  }

  @override
  List<Object?> get props => [freeMemoryLimit, memoryCount];
}

class MomentPlusOffering extends Equatable {
  const MomentPlusOffering({
    required this.plans,
    required this.features,
    required this.limits,
    this.subscription,
    this.entitlements = const [],
  });

  final List<SubscriptionPlan> plans;
  final List<String> features;
  final MomentPlusLimits limits;
  final UserSubscription? subscription;
  final List<String> entitlements;

  bool get isPremium => entitlements.contains('moment_plus');

  bool get canCreateMemory =>
      isPremium || limits.memoryCount < limits.freeMemoryLimit;

  @override
  List<Object?> get props => [
    plans,
    features,
    limits,
    subscription,
    entitlements,
  ];
}

class CheckoutResult extends Equatable {
  const CheckoutResult({
    required this.status,
    required this.message,
    this.planId,
  });

  final String status;
  final String message;
  final String? planId;

  @override
  List<Object?> get props => [status, message, planId];
}
