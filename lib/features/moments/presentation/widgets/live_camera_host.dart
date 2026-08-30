import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';
import 'package:moment/features/moments/presentation/pages/camera_preview_page.dart';

class LiveCameraSession {
  const LiveCameraSession({
    required this.viewfinder,
    required this.capturing,
    required this.flashEnabled,
    required this.capture,
    required this.flip,
    required this.toggleFlash,
    required this.pickGallery,
  });

  final Widget viewfinder;
  final bool capturing;
  final bool flashEnabled;
  final Future<void> Function() capture;
  final Future<void> Function() flip;
  final Future<void> Function() toggleFlash;
  final Future<void> Function() pickGallery;
}

class LiveCameraHost extends StatefulWidget {
  const LiveCameraHost({
    required this.builder,
    this.pauseWhenCovered = false,
    super.key,
  });

  final Widget Function(BuildContext context, LiveCameraSession session)
  builder;
  final bool pauseWhenCovered;

  @override
  State<LiveCameraHost> createState() => _LiveCameraHostState();
}

class _LiveCameraHostState extends State<LiveCameraHost>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  var _bindGeneration = 0;
  var _initializing = true;
  var _capturing = false;
  var _running = false;
  String? _error;
  GoRouterDelegate? _delegate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.pauseWhenCovered) {
      final delegate = GoRouter.of(context).routerDelegate;
      if (!identical(_delegate, delegate)) {
        _delegate?.removeListener(_syncPower);
        _delegate = delegate;
        _delegate?.addListener(_syncPower);
      }
    }
    _syncPower();
  }

  @override
  void dispose() {
    _delegate?.removeListener(_syncPower);
    WidgetsBinding.instance.removeObserver(this);
    _releaseController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _releaseController();
      _running = false;
    } else if (state == AppLifecycleState.resumed) {
      _syncPower();
    }
  }

  bool get _shouldRun {
    if (!TickerMode.valuesOf(context).enabled) return false;
    if (!widget.pauseWhenCovered) return true;
    try {
      final path = GoRouter.of(
        context,
      ).routerDelegate.currentConfiguration.uri.path;
      return path != AppRoutes.camera &&
          !path.startsWith('${AppRoutes.camera}/');
    } on Object {
      return true;
    }
  }

  void _syncPower() {
    if (!mounted) return;
    final shouldRun = _shouldRun;
    if (shouldRun && !_running) {
      _running = true;
      _openCamera();
    } else if (!shouldRun && _running) {
      _running = false;
      _releaseController();
      if (mounted) setState(() => _initializing = true);
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
      if (!mounted || !_shouldRun) return;
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
    if (!mounted || generation != _bindGeneration || !_shouldRun) return;

    final next = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await next.initialize();
      if (!mounted || generation != _bindGeneration || !_shouldRun) {
        await _disposeQuietly(next);
        return;
      }
      await next.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!mounted || generation != _bindGeneration || !_shouldRun) {
        await _disposeQuietly(next);
        return;
      }

      final flashOn = context.read<CameraCubit>().state.flashEnabled;
      if (next.description.lensDirection == CameraLensDirection.back) {
        await next.setFlashMode(flashOn ? FlashMode.auto : FlashMode.off);
      }
      if (!mounted || generation != _bindGeneration || !_shouldRun) {
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
      _openPreview(Uint8List.fromList(bytes), file.mimeType ?? 'image/jpeg');
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
        builder: (_) =>
            BlocProvider.value(value: cubit, child: const CameraPreviewPage()),
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

  Widget _viewfinder() {
    final controller = _controller;
    return ClipRRect(
      borderRadius: AppRadius.xxxlAll,
      child: ColoredBox(
        color: AppColors.surfaceDark,
        child: SizedBox.expand(
          child: _initializing
              ? const Center(
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
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: _openCamera,
                          child: const Text('Try again'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      LiveCameraSession(
        viewfinder: _viewfinder(),
        capturing: _capturing,
        flashEnabled: context.watch<CameraCubit>().state.flashEnabled,
        capture: _capture,
        flip: _flip,
        toggleFlash: _toggleFlash,
        pickGallery: () => _pickImage(ImageSource.gallery),
      ),
    );
  }
}
