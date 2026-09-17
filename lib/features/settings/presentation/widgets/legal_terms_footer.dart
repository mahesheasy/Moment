import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/moment_theme.dart';

/// Terms + Privacy links for auth screens (login & register).
class LegalTermsFooter extends StatelessWidget {
  const LegalTermsFooter({
    this.leadingText = 'By creating an account, you agree to our ',
    super.key,
  });

  final String leadingText;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final baseStyle = TextStyle(color: mc.textTertiary, fontSize: 11, height: 1.45);
    final linkStyle = TextStyle(
      color: mc.accent,
      fontSize: 11,
      height: 1.45,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
      decorationColor: mc.accent.withValues(alpha: 0.5),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(leadingText, style: baseStyle, textAlign: TextAlign.center),
        _LegalLink(
          label: 'Terms of Service',
          style: linkStyle,
          onTap: () => context.push(AppRoutes.termsOfService),
        ),
        Text(' and ', style: baseStyle),
        _LegalLink(
          label: 'Privacy Policy',
          style: linkStyle,
          onTap: () => context.push(AppRoutes.privacyPolicy),
        ),
        Text('.', style: baseStyle),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.style,
    required this.onTap,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(label, style: style),
      ),
    );
  }
}
