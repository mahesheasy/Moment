import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/auth/data/app_permissions_service.dart';
import 'package:moment/features/auth/data/datasources/setup_preferences_local_cache.dart';
import 'package:moment/features/auth/presentation/widgets/auth_chrome.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

enum _PermissionRowStatus { waiting, requesting, granted, denied }

class PermissionsSetupPage extends StatefulWidget {
  const PermissionsSetupPage({super.key});

  @override
  State<PermissionsSetupPage> createState() => _PermissionsSetupPageState();
}

class _PermissionsSetupPageState extends State<PermissionsSetupPage>
    with WidgetsBindingObserver {
  final _permissions = AppPermissionsService.items;
  final _statuses = <_PermissionRowStatus>[
    for (var i = 0; i < AppPermissionsService.items.length; i++)
      _PermissionRowStatus.waiting,
  ];

  var _running = false;
  var _finished = false;
  var _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSetup());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_pollActivePermission());
    }
  }

  Future<void> _finish({required bool skipped}) async {
    if (_finished) return;
    _finished = true;
    _running = false;
    if (mounted) setState(() {});

    await sl<SetupPreferencesLocalCache>().markPermissionsSetupComplete();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  Future<void> _pollActivePermission() async {
    if (!_running || _finished || !mounted) return;
    if (_activeIndex >= _permissions.length) return;
    if (_statuses[_activeIndex] != _PermissionRowStatus.requesting) return;

    final service = sl<AppPermissionsService>();
    final granted = await service.isGranted(_permissions[_activeIndex].kind);
    if (!mounted || !_running || _finished) return;

    if (granted) {
      setState(() {
        _statuses[_activeIndex] = _PermissionRowStatus.granted;
      });
    }
  }

  Future<_PermissionRowStatus> _resolvePermission(SetupPermissionKind kind) async {
    final service = sl<AppPermissionsService>();

    if (await service.isGranted(kind)) {
      return _PermissionRowStatus.granted;
    }

    unawaited(
      service.request(kind).timeout(
        const Duration(seconds: 8),
        onTimeout: () => PermissionStatus.denied,
      ),
    );

    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(deadline)) {
      if (!mounted || _finished) return _PermissionRowStatus.denied;
      if (await service.isGranted(kind)) {
        return _PermissionRowStatus.granted;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    return (await service.isGranted(kind))
        ? _PermissionRowStatus.granted
        : _PermissionRowStatus.denied;
  }

  Future<void> _runSetup() async {
    if (_running || _finished) return;
    _running = true;
    if (mounted) setState(() {});

    for (var i = 0; i < _permissions.length; i++) {
      if (!mounted || _finished) return;

      setState(() {
        _activeIndex = i;
        _statuses[i] = _PermissionRowStatus.requesting;
      });

      final result = await _resolvePermission(_permissions[i].kind);
      if (!mounted || _finished) return;

      setState(() => _statuses[i] = result);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted || _finished) return;
    setState(() => _running = false);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) await _finish(skipped: false);
  }

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final height = MediaQuery.sizeOf(context).height;
    final compact = height < 760;
    final heroHeight = compact ? 108.0 : 128.0;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: AuthAmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    AuthGradientText(
                      text: 'Moment',
                      style: SettingsType.title(mc.accent).copyWith(
                        fontSize: compact ? 24 : 26,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showWhyDialog(context, mc.accent),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            color: mc.accent,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Why we need this?',
                            style: SettingsType.caption(mc.accent).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Setting up Moment for you ✨',
                  textAlign: TextAlign.center,
                  style: SettingsType.title(Colors.white).copyWith(
                    fontSize: compact ? 19 : 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'ll automatically get the permissions we need to make your experience seamless.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SettingsType.body(mc.textSecondary).copyWith(
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: compact ? 8 : 12),
                SizedBox(
                  height: heroHeight,
                  child: Image.asset(
                    'assets/images/setup/permissions_hero.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 6),
                const _SetupStepper(activeStep: 0),
                const SizedBox(height: 10),
                Expanded(
                  child: _PermissionsCard(
                    statuses: _statuses,
                    activeIndex: _activeIndex,
                    running: _running && !_finished,
                    compact: compact,
                  ),
                ),
                const SizedBox(height: 8),
                _PrivacyBanner(compact: compact),
                TextButton(
                  onPressed: _finished ? null : () => _finish(skipped: true),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Skip for now',
                    style: SettingsType.body(mc.textSecondary).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWhyDialog(BuildContext context, Color accent) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text(
          'Why we need this',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Camera and gallery let you capture and share moments. '
          'Contacts help you find friends. Notifications keep you '
          'updated when friends send you something new.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Got it', style: TextStyle(color: accent)),
          ),
        ],
      ),
    );
  }
}

class _SetupStepper extends StatelessWidget {
  const _SetupStepper({required this.activeStep});

  final int activeStep;

  static const _labels = [
    'Permissions',
    'Personalize',
    'Stay Updated',
    'All Set',
  ];

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return Row(
      children: List.generate(_labels.length * 2 - 1, (index) {
        if (index.isOdd) {
          final step = index ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 14),
              color: step < activeStep
                  ? mc.accent
                  : Colors.white.withValues(alpha: 0.12),
            ),
          );
        }

        final step = index ~/ 2;
        final active = step == activeStep;
        final done = step < activeStep;

        return Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active || done ? mc.accent : const Color(0xFF1E1E1E),
                border: Border.all(
                  color: active ? mc.accent : Colors.white24,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: active || done ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 58,
              child: Text(
                _labels[step],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? mc.accent : Colors.white54,
                  fontSize: 8.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard({
    required this.statuses,
    required this.activeIndex,
    required this.running,
    required this.compact,
  });

  final List<_PermissionRowStatus> statuses;
  final int activeIndex;
  final bool running;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;

    return Container(
      padding: EdgeInsets.fromLTRB(14, compact ? 12 : 14, 14, compact ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  running ? 'Getting permissions...' : 'All permissions set',
                  style: SettingsType.title(Colors.white).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 16 : 17,
                  ),
                ),
              ),
              if (running)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: mc.accent,
                  ),
                ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: AppPermissionsService.items.length,
              separatorBuilder: (_, _) => SizedBox(height: compact ? 6 : 8),
              itemBuilder: (context, index) {
                return _PermissionRow(
                  item: AppPermissionsService.items[index],
                  status: statuses[index],
                  highlighted: index == activeIndex && running,
                  compact: compact,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.lock_rounded, size: 12, color: mc.textTertiary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'We never share your data with anyone.',
                  style: SettingsType.caption(mc.textTertiary).copyWith(
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.item,
    required this.status,
    required this.highlighted,
    required this.compact,
  });

  final SetupPermissionItem item;
  final _PermissionRowStatus status;
  final bool highlighted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final iconSize = compact ? 34.0 : 36.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? mc.accent.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: highlighted
            ? Border.all(color: mc.accent.withValues(alpha: 0.25))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: compact ? 18 : 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: SettingsType.title(Colors.white).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SettingsType.caption(mc.textSecondary).copyWith(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(status: status, accent: mc.accent),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.accent});

  final _PermissionRowStatus status;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      _PermissionRowStatus.waiting => Text(
        'Waiting...',
        style: SettingsType.caption(Colors.white38).copyWith(fontSize: 10),
      ),
      _PermissionRowStatus.requesting => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          ),
          const SizedBox(width: 4),
          Text(
            'Requesting...',
            style: SettingsType.caption(accent).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      _PermissionRowStatus.granted => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: accent, size: 14),
          const SizedBox(width: 3),
          Text(
            'Allowed',
            style: SettingsType.caption(accent).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      _PermissionRowStatus.denied => Text(
        'Skipped',
        style: SettingsType.caption(Colors.white38).copyWith(fontSize: 10),
      ),
    };
  }
}

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: mc.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mc.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, color: mc.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Private & Secure',
                  style: SettingsType.title(Colors.white).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Change permissions anytime in settings.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SettingsType.caption(mc.textSecondary).copyWith(
                    fontSize: 10,
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
