import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/subscription/domain/entities/subscription.dart';
import 'package:moment/features/subscription/presentation/cubit/premium_cubit.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

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

const _featurePairs = [
  ('Premium widgets', 'Advanced circles'),
  ('Premium themes', 'Custom prompts'),
  ('Unlimited memories', 'Premium memory themes'),
  ('Time Travel+', 'HD archive'),
];

const _extraFeatures = [
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
          return Scaffold(
            body: Center(child: MomentLoading()),
          );
        }
        if (state.status == PremiumStatus.failure && state.offering == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Moment+'),
            ),
            body: MomentErrorState(
              message: state.errorMessage ?? 'Could not load Moment+.',
              actionLabel: 'Retry',
              onAction: () => context.read<PremiumCubit>().load(),
            ),
          );
        }

        final offering = state.offering;
        if (offering == null) {
          return Scaffold(
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
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: Icon(AppIcons.back, size: 18),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Moment+',
              style: SettingsType.title(AppColors.textPrimaryDark)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.huge,
            ),
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
                            style: SettingsType.title(AppColors.textPrimaryDark)
                                .copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            children: [
                              const TextSpan(text: 'Make every moment '),
                              TextSpan(
                                text: 'yours.',
                                style: TextStyle(
                                  foreground: Paint()
                                    ..shader = AppColors.bloomGradient
                                        .createShader(
                                      const Rect.fromLTWH(0, 0, 80, 30),
                                    ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          isPremium
                              ? 'Premium customization and unlimited memories are unlocked.'
                              : 'Moment+ adds customization, memories, and more to make Moment truly yours.',
                          style: SettingsType.body(AppColors.textTertiaryDark),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/premium_crown.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppColors.bloomGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xl),
              Text(
                'Everything in Moment+',
                style: SettingsType.title(AppColors.textPrimaryDark)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderDark.withValues(alpha: 0.8),
                  ),
                ),
                child: Column(
                  children: [
                    for (final pair in _featurePairs) ...[
                      _FeatureRow(left: pair.$1, right: pair.$2),
                      if (pair != _featurePairs.last)
                        Divider(
                          height: 20,
                          color: AppColors.borderDark.withValues(alpha: 0.5),
                        ),
                    ],
                    for (final extra in _extraFeatures) ...[
                      Divider(
                        height: 20,
                        color: AppColors.borderDark.withValues(alpha: 0.5),
                      ),
                      _FeatureRow(left: extra, right: null),
                    ],
                  ],
                ),
              ),
              if (!isPremium) ...[
                SizedBox(height: AppSpacing.xl),
                Text(
                  'Choose your plan',
                  style: SettingsType.title(AppColors.textPrimaryDark)
                      .copyWith(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      SizedBox(width: 10),
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
                SizedBox(height: AppSpacing.xl),
                _PremiumContinueButton(
                  isLoading: isCheckingOut,
                  enabled: !isCheckingOut && state.selectedPlanId != null,
                  onTap: () => context.read<PremiumCubit>().subscribe(),
                ),
              ],
              SizedBox(height: AppSpacing.xl),
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.left, this.right});

  final String left;
  final String? right;

  @override
  Widget build(BuildContext context) {
    if (right == null) {
      return _FeatureCell(label: left);
    }
    return Row(
      children: [
        Expanded(child: _FeatureCell(label: left)),
        SizedBox(width: 8),
        Expanded(child: _FeatureCell(label: right!)),
      ],
    );
  }
}

class _FeatureCell extends StatelessWidget {
  const _FeatureCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_rounded, size: 16, color: AppColors.violet),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: SettingsType.caption(AppColors.textSecondaryDark)
                .copyWith(fontSize: 12),
          ),
        ),
      ],
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
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentSoftDark.withValues(alpha: 0.35)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.violet : AppColors.borderDark,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                  ).copyWith(fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ),
            if (badge != null) SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.violet
                          : AppColors.textTertiaryDark,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.violet,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: SettingsType.title(AppColors.textPrimaryDark)
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 20),
                children: [
                  TextSpan(text: plan.formattedPrice),
                  TextSpan(
                    text: isMonthly ? '/mo' : '/yr',
                    style: SettingsType.caption(AppColors.textTertiaryDark)
                        .copyWith(fontSize: 11, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4),
            Text(
              isMonthly ? 'Billed monthly' : 'Billed yearly',
              style: SettingsType.caption(AppColors.textTertiaryDark)
                  .copyWith(fontSize: 10, fontWeight: FontWeight.w400),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 6),
              Text(
                subtitle!,
                style: SettingsType.caption(
                  isMonthly ? AppColors.textTertiaryDark : AppColors.violet,
                ).copyWith(fontSize: 10, fontWeight: FontWeight.w400),
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
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: AppColors.bloomGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: isLoading
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Continue',
                        style: SettingsType.title(Colors.white)
                            .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: AppColors.violet, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free includes $limit saved memories.',
                  style: SettingsType.body(AppColors.textSecondaryDark),
                ),
                Text(
                  'You have $count.',
                  style: SettingsType.caption(AppColors.textTertiaryDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
