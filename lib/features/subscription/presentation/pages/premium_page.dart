import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';
import 'package:moment/features/subscription/domain/entities/subscription.dart';
import 'package:moment/features/subscription/presentation/cubit/premium_cubit.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PremiumCubit>()..load(),
      child: const _PremiumView(),
    );
  }
}

const _features = [
  'Premium widgets',
  'Advanced circles',
  'Premium themes',
  'Custom prompts',
  'Unlimited memories',
  'Premium memory themes',
  'Time Travel+',
  'HD archive',
  'Circles — private groups for your people',
  'Home widget themes — Love, Family, Friends & Bestie',
];

class _PremiumView extends StatelessWidget {
  const _PremiumView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PremiumCubit, PremiumState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.checkoutMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.checkoutMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == PremiumStatus.loading && state.offering == null) {
          return const Scaffold(
            body: Center(child: MomentLoading()),
          );
        }
        if (state.status == PremiumStatus.failure && state.offering == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Moment+')),
            body: MomentErrorState(
              message: state.errorMessage ?? 'Could not load Moment+.',
              actionLabel: 'Retry',
              onAction: () => context.read<PremiumCubit>().load(),
            ),
          );
        }

        final offering = state.offering;
        if (offering == null) {
          return const Scaffold(
            body: Center(child: MomentLoading()),
          );
        }

        final isPremium = offering.isPremium;
        final isCheckingOut = state.status == PremiumStatus.checkingOut;
        final monthly = offering.plans
            .where((p) => p.interval == BillingInterval.month)
            .firstOrNull;
        final yearly = offering.plans
            .where((p) => p.interval == BillingInterval.year)
            .firstOrNull;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColors.backgroundDark,
            leading: IconButton(
              icon: const Icon(AppIcons.back, size: 18),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Moment+',
              style: SettingsType.title(Colors.white).copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: SettingsType.title(Colors.white).copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                            children: [
                              const TextSpan(text: 'Make every moment '),
                              TextSpan(
                                text: 'yours.',
                                style: TextStyle(
                                  foreground: Paint()
                                    ..shader = AppColors.bloomGradient
                                        .createShader(
                                      const Rect.fromLTWH(0, 0, 90, 32),
                                    ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isPremium
                              ? 'Premium customization and unlimited memories are unlocked.'
                              : 'Moment+ adds customization, memories, and more to make Moment truly yours.',
                          style: SettingsType.body(
                            AppColors.textSecondaryDark,
                          ).copyWith(
                            fontSize: 14,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/premium_crown.png',
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: AppColors.bloomGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Everything in Moment+',
                style: SettingsType.title(Colors.white).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < _features.length; i++) ...[
                      _FeatureItem(label: _features[i]),
                      if (i != _features.length - 1)
                        const SizedBox(height: 2),
                    ],
                  ],
                ),
              ),
              if (!isPremium) ...[
                const SizedBox(height: 28),
                Text(
                  'Choose your plan',
                  style: SettingsType.title(Colors.white).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (monthly != null)
                        Expanded(
                          child: _PlanCard(
                            plan: monthly,
                            selected: state.selectedPlanId == monthly.id,
                            badge: 'Popular',
                            subtitle: 'Cancel anytime',
                            onTap: isCheckingOut
                                ? null
                                : () => context
                                    .read<PremiumCubit>()
                                    .selectPlan(monthly.id),
                          ),
                        ),
                      if (monthly != null && yearly != null)
                        const SizedBox(width: 10),
                      if (yearly != null)
                        Expanded(
                          child: _PlanCard(
                            plan: yearly,
                            selected: state.selectedPlanId == yearly.id,
                            badge: 'Save 41%',
                            onTap: isCheckingOut
                                ? null
                                : () => context
                                    .read<PremiumCubit>()
                                    .selectPlan(yearly.id),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _PremiumContinueButton(
                  isLoading: isCheckingOut,
                  enabled: !isCheckingOut && state.selectedPlanId != null,
                  onTap: () => context.read<PremiumCubit>().subscribe(),
                ),
              ],
              const SizedBox(height: 24),
              _FreeTierFooter(
                limit: offering.limits.freeMemoryLimit,
                count: offering.limits.memoryCount,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.check_rounded,
              size: 17,
              color: AppColors.violet,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: SettingsType.body(AppColors.textSecondaryDark).copyWith(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
    this.badge,
    this.subtitle,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback? onTap;
  final String? badge;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isMonthly = plan.interval == BillingInterval.month;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violet.withValues(alpha: 0.12)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.violet.withValues(alpha: 0.2)
                          : AppColors.surfaceElevatedDark,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: SettingsType.caption(
                        selected ? AppColors.violet : AppColors.textTertiaryDark,
                      ).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.violet
                        : Colors.transparent,
                    border: selected
                        ? null
                        : Border.all(
                            color: AppColors.textTertiaryDark
                                .withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: SettingsType.title(Colors.white).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  height: 1.1,
                ),
                children: [
                  TextSpan(text: plan.formattedPrice),
                  TextSpan(
                    text: isMonthly ? '/mo' : '/yr',
                    style: SettingsType.caption(AppColors.textTertiaryDark)
                        .copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isMonthly ? 'Billed monthly' : 'Billed yearly',
              style: SettingsType.caption(AppColors.textTertiaryDark).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: SettingsType.caption(
                  isMonthly ? AppColors.textTertiaryDark : AppColors.violet,
                ).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumContinueButton extends StatelessWidget {
  const _PremiumContinueButton({
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled || isLoading ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled && !isLoading ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: AppColors.bloomGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Continue',
                        style: SettingsType.title(Colors.white).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _FreeTierFooter extends StatelessWidget {
  const _FreeTierFooter({required this.limit, required this.count});

  final int limit;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: AppColors.violet.withValues(alpha: 0.9),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free includes $limit saved memories.',
                  style: SettingsType.body(AppColors.textSecondaryDark).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You have $count.',
                  style: SettingsType.caption(AppColors.textTertiaryDark).copyWith(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
