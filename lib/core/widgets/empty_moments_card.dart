import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

/// Polaroid illustration card for empty / caught-up moment states.
class EmptyMomentsCard extends StatelessWidget {
  const EmptyMomentsCard({
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
    this.onTap,
    super.key,
  });

  static const assetPath = 'assets/images/empty_moments_polaroid.png';

  final String title;
  final String? subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: mc.cardGradient,
            border: Border.all(
              color: mc.border.withValues(alpha: 0.7),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    assetPath,
                    width: 96,
                    height: 84,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: SettingsType.body(mc.textPrimary)
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: SettingsType.caption(mc.textTertiary)
                              .copyWith(height: 1.35),
                        ),
                      ],
                      if (buttonLabel != null && onButtonTap != null) ...[
                        const SizedBox(height: 10),
                        _CaptureButton(
                          label: buttonLabel!,
                          onTap: onButtonTap!,
                        ),
                      ],
                    ],
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

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: mc.bloomGradient,
        boxShadow: [
          BoxShadow(
            color: mc.accent.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.camera_alt_rounded,
                  size: 13,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: SettingsType.caption(Colors.white).copyWith(
                    fontWeight: FontWeight.w500,
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
