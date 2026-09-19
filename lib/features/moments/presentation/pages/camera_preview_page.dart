import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/moments/presentation/cubit/moment_cubit.dart';
import 'package:moment/features/moments/presentation/pages/camera_send_to_page.dart';
import 'package:moment/features/moments/presentation/widgets/camera_chrome.dart';
import 'package:moment/features/moments/presentation/widgets/camera_preview_caption_field.dart';
import 'package:moment/features/moments/presentation/widgets/camera_preview_header.dart';
import 'package:moment/features/moments/presentation/widgets/camera_preview_photo_card.dart';
import 'package:moment/features/moments/presentation/widgets/moment_detail_arc.dart';
import 'package:moment/features/moments/presentation/widgets/moment_detail_arc_panel.dart';

class CameraPreviewPage extends StatefulWidget {
  const CameraPreviewPage({super.key});

  @override
  State<CameraPreviewPage> createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends State<CameraPreviewPage> {
  static const int _captionLimit = 200;

  late final TextEditingController _captionController;
  late final TextEditingController _reviewController;
  MomentDetailType _selectedDetail = MomentDetailType.review;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<CameraCubit>();
    _captionController = TextEditingController(text: cubit.state.caption);
    _reviewController = TextEditingController(text: cubit.state.reviewText);
    if (cubit.state.timeLabel == null) {
      unawaited(cubit.loadMomentContext());
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraCubit, CameraState>(
      builder: (context, state) {
        final bytes = state.imageBytes;
        final arcItems = momentDetailArcItems(state);

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
                  const CameraPreviewHeader(),
                  const SizedBox(height: AppSpacing.sm),
                  const Expanded(child: CameraPreviewPhotoCard()),
                  const SizedBox(height: AppSpacing.md),
                  CameraPreviewCaptionField(
                    controller: _captionController,
                    maxLength: _captionLimit,
                    onChanged: context.read<CameraCubit>().setCaption,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0E10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 168,
                            child: MomentDetailArc(
                              items: arcItems,
                              initialType: _selectedDetail,
                              onSelected: (type) {
                                if (_selectedDetail != type) {
                                  setState(() => _selectedDetail = type);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          MomentDetailArcPanel(
                            selectedType: _selectedDetail,
                            reviewController: _reviewController,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
