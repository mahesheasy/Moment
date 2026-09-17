import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_component_sizes.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/moment_theme.dart';

/// Dark auth backdrop with soft accent glows.
class AuthAmbientBackground extends StatelessWidget {
  const AuthAmbientBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: mc.background),
        Positioned(
          top: -80,
          left: -40,
          child: IgnorePointer(
            child: _GlowBlob(color: mc.accent.withValues(alpha: 0.22), size: 220),
          ),
        ),
        Positioned(
          top: 40,
          right: -60,
          child: IgnorePointer(
            child: _GlowBlob(
              color: mc.sendCoral.withValues(alpha: 0.16),
              size: 180,
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -30,
          child: IgnorePointer(
            child: _GlowBlob(
              color: mc.accent.withValues(alpha: 0.1),
              size: 160,
            ),
          ),
        ),
        SizedBox.expand(child: child),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class AuthLogoMark extends StatelessWidget {
  const AuthLogoMark({super.key});

  static const assetPath = 'assets/images/auth_logo_m.png';
  static const size = 96.0;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: mc.accent.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
      ),
    );
  }
}

class AuthGradientText extends StatelessWidget {
  const AuthGradientText({
    required this.text,
    required this.style,
    super.key,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          context.mc.bloomGradient.createShader(bounds),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    super.key,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.autofillHints,
    this.prefixText,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final List<String>? autofillHints;
  final String? prefixText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  var _obscured = true;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final isPassword = widget.obscureText;

    return TextFormField(
      controller: widget.controller,
      obscureText: isPassword && _obscured,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      autocorrect: widget.autocorrect,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      style: TextStyle(
        color: mc.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      cursorColor: mc.accent,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: mc.textTertiary, fontSize: 14),
        prefixIcon: Icon(widget.icon, size: 18, color: mc.textTertiary),
        prefixText: widget.prefixText,
        prefixStyle: TextStyle(color: mc.textSecondary, fontSize: 14),
        errorStyle: TextStyle(color: mc.error, fontSize: 11, height: 1.2),
        errorMaxLines: 2,
        suffixIcon: isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: mc.textTertiary,
                ),
              )
            : null,
        filled: true,
        fillColor: mc.surface.withValues(alpha: 0.92),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: mc.border.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: mc.border.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: mc.accent.withValues(alpha: 0.55)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: mc.error.withValues(alpha: 0.75)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: mc.error),
        ),
      ),
    );
  }
}

class AuthGradientButton extends StatelessWidget {
  const AuthGradientButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final enabled = onPressed != null && !isLoading;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: mc.bloomGradient,
              boxShadow: [
                BoxShadow(
                  color: mc.accent.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: AppComponentSizes.buttonHeightLg + 8,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return Row(
      children: [
        Expanded(child: Divider(color: mc.border.withValues(alpha: 0.5))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'or continue with',
            style: TextStyle(color: mc.textTertiary, fontSize: 11),
          ),
        ),
        Expanded(child: Divider(color: mc.border.withValues(alpha: 0.5))),
      ],
    );
  }
}

enum AuthSocialProvider { google, apple, facebook }

class AuthSocialRow extends StatelessWidget {
  const AuthSocialRow({super.key, this.onTap});

  final void Function(AuthSocialProvider provider)? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          provider: AuthSocialProvider.google,
          onTap: () => onTap?.call(AuthSocialProvider.google),
        ),
        const SizedBox(width: AppSpacing.lg),
        _SocialButton(
          provider: AuthSocialProvider.apple,
          onTap: () => onTap?.call(AuthSocialProvider.apple),
        ),
        const SizedBox(width: AppSpacing.lg),
        _SocialButton(
          provider: AuthSocialProvider.facebook,
          onTap: () => onTap?.call(AuthSocialProvider.facebook),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.provider, this.onTap});

  final AuthSocialProvider provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return Material(
      color: mc.surface.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: mc.border.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Center(child: _SocialIcon(provider: provider)),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.provider});

  final AuthSocialProvider provider;

  @override
  Widget build(BuildContext context) {
    return switch (provider) {
      AuthSocialProvider.google => const _GoogleMark(),
      AuthSocialProvider.apple => Icon(
        Icons.apple,
        size: 24,
        color: context.mc.textPrimary,
      ),
      AuthSocialProvider.facebook => Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFF1877F2),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            'f',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1,
            ),
          ),
        ),
      ),
    };
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius, Paint()..color = Colors.white);

    void arc(Color color, double start, double sweep) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1.5),
        start,
        sweep,
        true,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    arc(const Color(0xFF4285F4), -0.55, 1.55);
    arc(const Color(0xFF34A853), 1.0, 1.05);
    arc(const Color(0xFFFBBC05), 2.05, 1.0);
    arc(const Color(0xFFEA4335), 3.05, 0.95);

    canvas.drawCircle(
      center,
      radius * 0.56,
      Paint()..color = Colors.white,
    );

    final bar = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx + radius * 0.08, center.dy),
        width: radius * 0.95,
        height: radius * 0.28,
      ),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return Material(
      color: mc.surface.withValues(alpha: 0.7),
      shape: CircleBorder(
        side: BorderSide(color: mc.border.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.onboarding);
          }
        },
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: mc.textPrimary),
        ),
      ),
    );
  }
}

void showAuthComingSoon(BuildContext context, String provider) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$provider sign-in coming soon.')),
  );
}
