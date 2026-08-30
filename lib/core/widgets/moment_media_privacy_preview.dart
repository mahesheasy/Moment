import 'dart:ui';

import 'package:flutter/material.dart';

/// Progressive 5-second privacy blur for moment media only.
///
/// Per-view session: clear → smooth blur → fully blurred.
/// Metadata/overlays placed outside this widget stay sharp.
class MomentMediaPrivacyPreview extends StatefulWidget {
  const MomentMediaPrivacyPreview({
    required this.child,
    this.enabled = true,
    this.duration = const Duration(seconds: 5),
    this.maxBlurSigma = 18,
    super.key,
  });

  final Widget child;
  final bool enabled;
  final Duration duration;
  final double maxBlurSigma;

  @override
  State<MomentMediaPrivacyPreview> createState() =>
      _MomentMediaPrivacyPreviewState();
}

class _MomentMediaPrivacyPreviewState extends State<MomentMediaPrivacyPreview>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPreview();
  }

  @override
  void didUpdateWidget(covariant MomentMediaPrivacyPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _startPreview();
    } else if (!widget.enabled && oldWidget.enabled) {
      _controller
        ?..stop()
        ..value = 0;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _protectImmediately();
      case AppLifecycleState.resumed:
        _startPreview();
    }
  }

  void _startPreview() {
    if (!widget.enabled) return;
    final controller = _controller ??= AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (controller.duration != widget.duration) {
      controller.duration = widget.duration;
    }
    controller
      ..reset()
      ..forward();
  }

  void _protectImmediately() {
    if (!mounted || _controller == null) return;
    _controller!.value = 1;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final controller = _controller;
    if (controller == null) return widget.child;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final sigma = widget.maxBlurSigma * controller.value;
        if (sigma < 0.15) return child!;
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
