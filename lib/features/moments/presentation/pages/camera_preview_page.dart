import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_icons.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_states.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';
import 'package:moment/features/moments/presentation/pages/camera_send_to_page.dart';
import 'package:moment/features/moments/presentation/widgets/camera_chrome.dart';

class CameraPreviewPage extends StatefulWidget {
  const CameraPreviewPage({super.key});

  @override
  State<CameraPreviewPage> createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends State<CameraPreviewPage> {
  late final TextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(
      text: context.read<CameraCubit>().state.caption,
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _comingSoon(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label is coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraCubit, CameraState>(
      builder: (context, state) {
        final bytes = state.imageBytes;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          AppIcons.back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Preview',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      SizedBox(width: 48),
                    ],
                  ),
                  TextField(
                    controller: _captionController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    cursorColor: AppColors.violet,
                    decoration: InputDecoration(
                      hintText: 'Add a caption...',
                      hintStyle: TextStyle(color: AppColors.textTertiaryDark),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: context.read<CameraCubit>().setCaption,
                  ),
                  if (state.isPromptMode && state.promptText != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        state.promptText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadius.xxxlAll,
                      child: bytes == null
                          ? MomentShimmer(
                              child: ColoredBox(
                                color: AppColors.photoPlaceholderDark,
                              ),
                            )
                          : Image.memory(bytes, fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToolButton(
                        icon: AppIcons.wand,
                        label: 'Edit',
                        onTap: () => _comingSoon('Edit'),
                      ),
                      _ToolButton(
                        icon: AppIcons.stickers,
                        label: 'Stickers',
                        onTap: () => _comingSoon('Stickers'),
                      ),
                      _ToolButton(
                        icon: AppIcons.draw,
                        label: 'Draw',
                        onTap: () => _comingSoon('Draw'),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  CameraGradientButton(
                    label: 'Next',
                    onPressed: bytes == null
                        ? null
                        : () {
                            final cubit = context.read<CameraCubit>();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BlocProvider.value(
                                  value: cubit,
                                  child: const CameraSendToPage(),
                                ),
                              ),
                            );
                          },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
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
          Icon(icon, color: Colors.white, size: 26),
          SizedBox(height: AppSpacing.sm),
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
