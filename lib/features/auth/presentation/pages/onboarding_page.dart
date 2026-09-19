import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/auth/data/datasources/onboarding_preferences_local_cache.dart';

class OnboardingBackdrop {
  const OnboardingBackdrop._();

  static const Color edge = Color(0xFF0A0614);
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  var _index = 0;

  static const _slides = [
    'assets/images/onboarding/welcome.png',
    'assets/images/onboarding/share_moments.jpg',
    'assets/images/onboarding/your_people.png',
    'assets/images/onboarding/privacy.png',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool toRegister}) async {
    await sl<OnboardingPreferencesLocalCache>().markComplete();
    if (!mounted) return;
    context.go(toRegister ? AppRoutes.register : AppRoutes.login);
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _finish(toRegister: true);
  }

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;

    return Scaffold(
      backgroundColor: OnboardingBackdrop.edge,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, index) {
              return Image.asset(
                _slides[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.lg,
                  child: TextButton(
                    onPressed: () => _finish(toRegister: false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.xxl,
                  right: AppSpacing.xxl,
                  bottom: AppSpacing.xxl,
                  child: SizedBox(
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _slides.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              width: i == _index ? 8 : 7,
                              height: i == _index ? 8 : 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _index
                                    ? mc.accent
                                    : Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _OnboardingNextButton(onPressed: _next),
                        ),
                      ],
                    ),
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

class _OnboardingNextButton extends StatelessWidget {
  const _OnboardingNextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return Semantics(
      button: true,
      label: 'Next',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: mc.bloomGradient,
              boxShadow: [
                BoxShadow(
                  color: mc.accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
