import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/deep_links/moment_qr_link.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/auth/domain/repositories/auth_repository.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class FriendQrScanPage extends StatefulWidget {
  const FriendQrScanPage({super.key});

  @override
  State<FriendQrScanPage> createState() => _FriendQrScanPageState();
}

class _FriendQrScanPageState extends State<FriendQrScanPage> {
  MobileScannerController? _controller;

  var _handled = false;
  var _permissionChecked = false;
  var _permissionGranted = false;
  var _permissionDenied = false;
  DateTime? _lastInvalidNotice;

  @override
  void initState() {
    super.initState();
    _ensureCameraPermission();
  }

  Future<void> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;

    setState(() {
      _permissionChecked = true;
      _permissionGranted = status.isGranted;
      _permissionDenied = !status.isGranted;
    });

    if (status.isGranted) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
      );
    }
  }

  String? _readBarcode(Barcode barcode) {
    return barcode.rawValue?.trim().isNotEmpty == true
        ? barcode.rawValue!.trim()
        : barcode.displayValue?.trim();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || !_permissionGranted) return;

    String? raw;
    for (final barcode in capture.barcodes) {
      raw = _readBarcode(barcode);
      if (raw != null && raw.isNotEmpty) break;
    }
    if (raw == null || raw.isEmpty) return;

    final userId = MomentQrLink.parseUserId(raw);
    if (userId == null) {
      _showInvalidQrNotice();
      return;
    }

    final currentUserId = sl<AuthRepository>().currentUserId?.toLowerCase();
    if (currentUserId != null && currentUserId == userId.toLowerCase()) {
      _showOwnQrNotice();
      return;
    }

    _handled = true;
    _controller?.stop();
    context.push(AppRoutes.friend(userId)).then((_) {
      if (mounted) context.pop();
    });
  }

  void _showInvalidQrNotice() {
    final now = DateTime.now();
    if (_lastInvalidNotice != null &&
        now.difference(_lastInvalidNotice!) < const Duration(seconds: 2)) {
      return;
    }
    _lastInvalidNotice = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Not a Moment QR code. Try scanning a friend\'s QR.'),
      ),
    );
  }

  void _showOwnQrNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'That\'s your QR code. Ask a friend to scan it from their phone.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: !_permissionChecked
            ? Center(
                child: CircularProgressIndicator(color: AppColors.violet),
              )
            : _permissionDenied
            ? _PermissionDenied(
                onClose: context.pop,
                onRetry: () {
                  setState(() {
                    _permissionChecked = false;
                    _permissionDenied = false;
                  });
                  _ensureCameraPermission();
                },
              )
            : _ScannerBody(
                controller: _controller!,
                onDetect: _onDetect,
                onClose: context.pop,
              ),
      ),
    );
  }
}

class _ScannerBody extends StatelessWidget {
  const _ScannerBody({
    required this.controller,
    required this.onDetect,
    required this.onClose,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: controller,
          onDetect: onDetect,
        ),
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0, 0.2, 0.75, 1],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.close_rounded,
                    onTap: onClose,
                  ),
                  const Spacer(),
                  _RoundIconButton(
                    icon: Icons.flash_on_rounded,
                    onTap: () => controller.toggleTorch(),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Scan Moment QR',
                style: SettingsType.title(Colors.white).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Point at a friend\'s QR code to open their profile.',
                textAlign: TextAlign.center,
                style: SettingsType.body(
                  Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              IgnorePointer(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.violet.withValues(alpha: 0.85),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'You can\'t scan your own QR — use a friend\'s phone.',
                textAlign: TextAlign.center,
                style: SettingsType.caption(
                  Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({
    required this.onClose,
    required this.onRetry,
  });

  final VoidCallback onClose;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera_outlined, size: 48, color: AppColors.violet),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Camera access needed',
            style: SettingsType.title(AppColors.textPrimaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Allow camera access in Settings to scan Moment QR codes.',
            textAlign: TextAlign.center,
            style: SettingsType.body(AppColors.textSecondaryDark),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onClose, child: const Text('Cancel')),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
