import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/subscription/domain/entities/subscription.dart';

void main() {
  test('SubscriptionPlan formats INR prices from remote cents', () {
    const monthly = SubscriptionPlan(
      id: 'monthly',
      displayName: 'Monthly',
      priceCents: 9900,
      currency: 'INR',
      interval: BillingInterval.month,
    );
    const yearly = SubscriptionPlan(
      id: 'yearly',
      displayName: 'Yearly',
      priceCents: 69900,
      currency: 'INR',
      interval: BillingInterval.year,
    );

    expect(monthly.formattedPrice, '₹99');
    expect(yearly.formattedPrice, '₹699');
    expect(monthly.intervalLabel, '/month');
  });

  test('MomentPlusOffering canCreateMemory respects free limit', () {
    const offering = MomentPlusOffering(
      plans: [],
      features: [],
      limits: MomentPlusLimits(freeMemoryLimit: 3, memoryCount: 3),
    );

    expect(offering.canCreateMemory, isFalse);
  });
}
