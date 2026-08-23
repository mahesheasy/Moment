import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';
import 'package:moment/features/moments/presentation/pages/camera_preview_page.dart';
import 'package:moment/features/prompts/domain/entities/camera_prompt_context.dart';

class CameraPlaceholderPage extends StatelessWidget {
  const CameraPlaceholderPage({this.promptContext, super.key});

  final CameraPromptContext? promptContext;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CameraCubit>(param1: promptContext)..initialize(),
      child: const _CameraCaptureView(),
    );
  }
}

class _CameraCaptureView extends StatefulWidget {
  const _CameraCaptureView();

  @override
  State<_CameraCaptureView> createState() => _CameraCaptureViewState();
}

class _CameraCaptureViewState extends State<_CameraCaptureView>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  var _bindGeneration = 0;
  var _initializing = true;
  var _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _releaseController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _releaseController();
    } else if (state == AppLifecycleState.resumed) {
      final controller = _controller;
      if (controller == null || !controller.value.isInitialized) {
        _openCamera();
      }
    }
  }

  Future<void> _disposeQuietly(CameraController controller) async {
    try {
      await controller.dispose();
    } on Object {
      // Camera plugin channels can already be gone during hot restart
      // or Android activity teardown.
    }
  }

  Future<void> _releaseController() async {
    _bindGeneration++;
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await _disposeQuietly(controller);
    }
  }

  Future<void> _openCamera() async {
    if (kIsWeb) {
      setState(() => _initializing = false);
      return;
    }

    setState(() {
      _initializing = true;
      _error = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _error = 'No camera found on this device.';
        });
        return;
      }
      if (!mounted) return;
      await _bindCamera(context.read<CameraCubit>().state.useFrontCamera);
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = error.description ?? 'Camera access is required.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Could not start camera: $error';
      });
    }
  }

  Future<void> _bindCamera(bool useFront) async {
    final generation = ++_bindGeneration;
    final lens = useFront
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final description = _cameras.firstWhere(
      (camera) => camera.lensDirection == lens,
      orElse: () => _cameras.first,
    );

    final previous = _controller;
    _controller = null;
    if (previous != null) {
      try {
        await previous.dispose();
      } on Object {
        // Ignore stale plugin channels from a previous session.
      }
    }
    if (!mounted || generation != _bindGeneration) return;

    final next = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await next.initialize();
      if (!mounted || generation != _bindGeneration) {
        await _disposeQuietly(next);
        return;
      }
      await next.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!mounted || generation != _bindGeneration) {
        await _disposeQuietly(next);
        return;
      }

      final flashOn = context.read<CameraCubit>().state.flashEnabled;
      if (next.description.lensDirection == CameraLensDirection.back) {
        await next.setFlashMode(flashOn ? FlashMode.auto : FlashMode.off);
      }
      if (!mounted || generation != _bindGeneration) {
        await _disposeQuietly(next);
        return;
      }
      _controller = next;
      setState(() => _initializing = false);
    } on Object {
      await _disposeQuietly(next);
      rethrow;
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _capturing ||
        !mounted) {
      if (kIsWeb) {
        await _pickImage(ImageSource.gallery);
      }
      return;
    }

    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      _openPreview(Uint8List.fromList(bytes), 'image/jpeg');
    } on CameraException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.description ?? 'Could not capture.')),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      _openPreview(
        Uint8List.fromList(bytes),
        file.mimeType ?? 'image/jpeg',
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message?.isNotEmpty == true
                ? error.message!
                : 'Photos access is required. Enable it in Settings.',
          ),
        ),
      );
    }
  }

  void _openPreview(Uint8List bytes, String mimeType) {
    final cubit = context.read<CameraCubit>();
    cubit.setPreview(bytes: bytes, mimeType: mimeType);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const CameraPreviewPage(),
        ),
      ),
    );
  }

  Future<void> _flip() async {
    if (_cameras.length < 2 || _initializing) return;
    final cubit = context.read<CameraCubit>();
    cubit.toggleCameraFacing();
    setState(() => _initializing = true);
    await _bindCamera(cubit.state.useFrontCamera);
  }

  Future<void> _toggleFlash() async {
    final cubit = context.read<CameraCubit>();
    cubit.toggleFlash();
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.setFlashMode(
      cubit.state.flashEnabled ? FlashMode.auto : FlashMode.off,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CameraCubit, CameraState>(
      listener: (context, state) {
        if (state.errorMessage != null &&
            state.status == CameraStatus.failure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: BlocBuilder<CameraCubit, CameraState>(
                  buildWhen: (previous, current) =>
                      previous.flashEnabled != current.flashEnabled,
                  builder: (context, state) {
                    return Row(
                      children: [
                        _RoundIconButton(
                          icon: AppIcons.close,
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.pop();
                            }
                          },
                        ),
                        Spacer(),
                        _RoundIconButton(
                          icon: state.flashEnabled
                              ? AppIcons.flash
                              : AppIcons.flashOff,
                          onTap: _toggleFlash,
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Expanded(child: _viewfinder()),
              SizedBox(height: AppSpacing.xl),
              _CaptureBar(
                onGallery: () => _pickImage(ImageSource.gallery),
                onCapture: _capture,
                onFlip: _flip,
                capturing: _capturing,
              ),
              SizedBox(height: AppSpacing.lg),
              const _ModeSelector(),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewfinder() {
    final controller = _controller;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: AppRadius.xxxlAll,
        child: ColoredBox(
          color: AppColors.surfaceDark,
          child: SizedBox.expand(
            child: _initializing
                ? Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: AppSpacing.md),
                          TextButton(
                            onPressed: _openCamera,
                            child: Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : controller != null && controller.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: controller.value.previewSize?.height ?? 1,
                      height: controller.value.previewSize?.width ?? 1,
                      child: CameraPreview(controller),
                    ),
                  )
                : Center(
                    child: Icon(
                      AppIcons.camera,
                      size: 56,
                      color: AppColors.textTertiaryDark,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CaptureBar extends StatelessWidget {
  const _CaptureBar({
    required this.onGallery,
    required this.onCapture,
    required this.onFlip,
    this.capturing = false,
  });

  final VoidCallback onGallery;
  final VoidCallback onCapture;
  final VoidCallback onFlip;
  final bool capturing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _LabeledRoundButton(
            icon: AppIcons.gallery,
            label: 'Gallery',
            onTap: onGallery,
          ),
          GestureDetector(
            onTap: capturing ? null : onCapture,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
              ),
              child: capturing
                  ? Padding(
                      padding: EdgeInsets.all(22),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          _LabeledRoundButton(
            icon: AppIcons.flip,
            label: 'Flip',
            onTap: onFlip,
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'PHOTO',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.photoPink,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            '·',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.textTertiaryDark),
          ),
        ),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Video is coming soon.')),
            );
          },
          child: Text(
            'VIDEO',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textTertiaryDark,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledRoundButton extends StatelessWidget {
  const _LabeledRoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
