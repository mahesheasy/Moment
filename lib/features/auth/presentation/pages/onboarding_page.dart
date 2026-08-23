import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/auth/presentation/widgets/auth_chrome.dart';

/// Matches the edge/canvas color baked into onboarding artwork PNGs.
class OnboardingBackdrop {
  const OnboardingBackdrop._();

  static const Color edge = Color(0xFF0A0614);
  static const Color glow = Color(0xFF1A0B2E);

  static const LinearGradient canvas = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [glow, edge],
    stops: [0.0, 0.78],
  );

  static BoxDecoration get decoration => const BoxDecoration(gradient: canvas);
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  var _index = 0;

  static const _pages = [
    _OnboardingSlideData(
      imageAsset: 'assets/images/onboarding/capture.png',
      accentWord: 'Capture',
      titleRest: 'every moment',
      body: 'Save the little moments that matter the most.',
    ),
    _OnboardingSlideData(
      imageAsset: 'assets/images/onboarding/share.png',
      accentWord: 'Share',
      titleRest: 'with your people',
      body: 'Share privately and stay close to what matters.',
    ),
    _OnboardingSlideData(
      imageAsset: 'assets/images/onboarding/connected.png',
      accentWord: 'Stay',
      titleRest: 'connected',
      body: 'Private moments. Stronger connections.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    context.go(AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;

    return Scaffold(
      backgroundColor: OnboardingBackdrop.edge,
      body: DecoratedBox(
        decoration: OnboardingBackdrop.decoration,
        child: SafeArea(
          bottom: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.xxl,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    style: TextButton.styleFrom(
                      foregroundColor: mc.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: mc.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, index) => _OnboardingSlide(
                    data: _pages[index],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                child: SizedBox(
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _index
                                  ? mc.accent
                                  : mc.textTertiary.withValues(alpha: 0.35),
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
      ),
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.imageAsset,
    required this.accentWord,
    required this.titleRest,
    required this.body,
  });

  final String imageAsset;
  final String accentWord;
  final String titleRest;
  final String body;
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data});

  final _OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    const titleStyle = TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      height: 1.12,
    );

    return Column(
      children: [
        Expanded(
          flex: 11,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: OnboardingBackdrop.edge),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: double.infinity,
                  child: Image.asset(
                    data.imageAsset,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        OnboardingBackdrop.edge.withValues(alpha: 0),
                        OnboardingBackdrop.edge,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 9,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                AuthGradientText(
                  text: data.accentWord,
                  style: titleStyle,
                ),
                Text(
                  data.titleRest,
                  textAlign: TextAlign.center,
                  style: titleStyle.copyWith(color: mc.textPrimary),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  data.body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mc.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
