import 'dart:io';

import 'package:flutter/material.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/widget/android_widget_bridge.dart';
import 'package:moment/core/widget/widget_background_reliability.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class WidgetReliabilityCard extends StatefulWidget {
  const WidgetReliabilityCard({super.key});

  @override
  State<WidgetReliabilityCard> createState() => _WidgetReliabilityCardState();
}

class _WidgetReliabilityCardState extends State<WidgetReliabilityCard> {
  WidgetBackgroundReliabilityStatus? _status;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!Platform.isAndroid) {
      setState(() => _loading = false);
      return;
    }
    final status = await sl<AndroidWidgetBridge>().getBackgroundReliability();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  Future<void> _fixBattery() async {
    await sl<AndroidWidgetBridge>().requestBatteryOptimizationExemption();
    await Future<void>.delayed(const Duration(seconds: 1));
    await _load();
  }

  Future<void> _openAutostart() async {
    await sl<AndroidWidgetBridge>().openAutostartSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _status?.autostartGuidance ??
              'Enable Autostart and disable battery restrictions for Moment.',
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return const SizedBox.shrink();
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final status = _status;
    if (status == null) return const SizedBox.shrink();

    final batteryOk = status.batteryUnrestricted;
    final needsFix = status.needsAttention || !batteryOk;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: needsFix ? const Color(0xFF2A1F14) : const Color(0xFF141416),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: needsFix ? const Color(0x44FF8A3D) : const Color(0xFF2A2A2E),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                needsFix ? Icons.warning_amber_rounded : Icons.verified_rounded,
                color: needsFix ? const Color(0xFFFF8A3D) : AppColors.violet,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Keep widget updated',
                  style: SettingsType.title(Colors.white).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'On ${status.oemLabel} phones, battery optimization can block widget '
            'updates when the app is closed. This is the #1 reason widgets go stale in India.',
            style: SettingsType.body(AppColors.textSecondaryDark).copyWith(
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Battery unrestricted',
            ok: batteryOk,
          ),
          const SizedBox(height: 6),
          _StatusRow(
            label: 'Autostart recommended',
            ok: !status.needsAttention,
            hint: status.needsAttention ? 'Manual step required' : 'Looks good',
          ),
          if (needsFix) ...[
            const SizedBox(height: 14),
            if (!batteryOk)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _fixBattery,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A3D),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(42),
                  ),
                  child: const Text('Allow background updates'),
                ),
              ),
            if (!batteryOk && status.needsAttention) const SizedBox(height: 8),
            if (status.needsAttention)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _openAutostart,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF3A3A3E)),
                    minimumSize: const Size.fromHeight(42),
                  ),
                  child: const Text('Open Autostart settings'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.ok,
    this.hint,
  });

  final String label;
  final bool ok;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: ok ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: SettingsType.body(Colors.white).copyWith(fontSize: 13),
          ),
        ),
        if (hint != null)
          Text(
            hint!,
            style: SettingsType.body(AppColors.textSecondaryDark).copyWith(
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}
