import 'package:flutter/material.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_component_sizes.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/widgets/moment_controls.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';
import 'package:moment/features/circles/presentation/cubit/circles_cubit.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class CreateCircleSheet extends StatefulWidget {
  const CreateCircleSheet({this.initialType, super.key});

  final CircleType? initialType;

  static Future<Circle?> show(
    BuildContext context, {
    CircleType? initialType,
    required CirclesCubit cubit,
  }) {
    return showModalBottomSheet<Circle?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: CreateCircleSheet(initialType: initialType),
      ),
    );
  }

  @override
  State<CreateCircleSheet> createState() => _CreateCircleSheetState();
}

class _CreateCircleSheetState extends State<CreateCircleSheet> {
  final _nameController = TextEditingController();
  late CircleType _type;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? CircleType.squad;
    if (widget.initialType != null) {
      _nameController.text = widget.initialType!.label;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Give your circle a name.')),
      );
      return;
    }

    final cubit = context.read<CirclesCubit>();
    final circle = await cubit.createCircle(
      CreateCircleInput(
        name: name,
        type: _type,
        emoji: _type.defaultEmoji,
      ),
    );
    if (circle != null && mounted) {
      Navigator.of(context).pop(circle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreating =
        context.watch<CirclesCubit>().state.status == CirclesStatus.creating;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            SizedBox(height: 10),
            Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.borderDark,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New circle',
                          style: SettingsType.title(AppColors.textPrimaryDark),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pick a name and type. Invite friends after you create it.',
                          style: SettingsType.body(
                            AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded),
                    color: AppColors.textTertiaryDark,
                    iconSize: AppComponentSizes.iconMd,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                children: [
                  Text(
                    'Name',
                    style: SettingsType.caption(AppColors.violet),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    style: SettingsType.title(AppColors.textPrimaryDark),
                    cursorColor: AppColors.violet,
                    decoration: InputDecoration(
                      hintText: 'Weekend crew',
                      hintStyle: SettingsType.body(AppColors.textTertiaryDark),
                      filled: true,
                      fillColor: AppColors.surfaceDark,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.lgAll,
                        borderSide: BorderSide(color: AppColors.borderDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.lgAll,
                        borderSide: BorderSide(color: AppColors.borderDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.lgAll,
                        borderSide: BorderSide(
                          color: AppColors.violet,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Type',
                    style: SettingsType.caption(AppColors.violet),
                  ),
                  SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: AppRadius.lgAll,
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < CircleType.values.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: AppColors.borderDark,
                              indent: 52,
                            ),
                          _TypeRow(
                            type: CircleType.values[i],
                            selected: _type == CircleType.values[i],
                            onTap: () => setState(() {
                              _type = CircleType.values[i];
                              if (_nameController.text.trim().isEmpty ||
                                  CircleType.values.any(
                                    (t) =>
                                        t.label == _nameController.text.trim(),
                                  )) {
                                _nameController.text =
                                    CircleType.values[i].label;
                              }
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottom),
              child: SizedBox(
                width: double.infinity,
                height: AppComponentSizes.buttonHeightLg,
                child: FilledButton(
                  onPressed: isCreating ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.lgAll,
                    ),
                    textStyle: SettingsType.title(Colors.white),
                  ),
                  child: isCreating
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Create circle'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final CircleType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 11,
        ),
        child: Row(
          children: [
            Text(type.defaultEmoji, style: const TextStyle(fontSize: 18)),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                type.label,
                style: SettingsType.title(
                  selected
                      ? AppColors.textPrimaryDark
                      : AppColors.textSecondaryDark,
                ),
              ),
            ),
            MomentRadioIndicator(selected: selected),
          ],
        ),
      ),
    );
  }
}
