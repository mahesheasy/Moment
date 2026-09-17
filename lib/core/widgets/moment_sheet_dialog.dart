import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

class MomentBottomSheet {
  const MomentBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xxl,
            right: AppSpacing.xxl,
            top: AppSpacing.sm,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
              ],
              child,
            ],
          ),
        );
      },
    );
  }

  /// Confirmation sheet with [cancelLabel] and [confirmLabel] side by side.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.sm,
              AppSpacing.xxl,
              AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: SettingsType.title(AppColors.textPrimaryDark),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style: SettingsType.body(AppColors.textSecondaryDark),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: _ConfirmSheetButton(
                        label: cancelLabel,
                        style: _ConfirmSheetButtonStyle.cancel,
                        onPressed: () => Navigator.pop(sheetContext, false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ConfirmSheetButton(
                        label: confirmLabel,
                        style: destructive
                            ? _ConfirmSheetButtonStyle.destructive
                            : _ConfirmSheetButtonStyle.confirm,
                        onPressed: () => Navigator.pop(sheetContext, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }
}

enum _ConfirmSheetButtonStyle { cancel, confirm, destructive }

class _ConfirmSheetButton extends StatelessWidget {
  const _ConfirmSheetButton({
    required this.label,
    required this.style,
    required this.onPressed,
  });

  static const double _height = 48;

  final String label;
  final _ConfirmSheetButtonStyle style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final labelStyle = SettingsType.title(
      switch (style) {
        _ConfirmSheetButtonStyle.cancel => AppColors.textPrimaryDark,
        _ConfirmSheetButtonStyle.confirm => Colors.white,
        _ConfirmSheetButtonStyle.destructive => AppColors.error,
      },
    );

    return SizedBox(
      height: _height,
      width: double.infinity,
      child: switch (style) {
        _ConfirmSheetButtonStyle.cancel => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(_height),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: AppColors.borderDark),
          ),
          child: Text(label, style: labelStyle),
        ),
        _ConfirmSheetButtonStyle.confirm => ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(_height),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
          child: Text(label, style: labelStyle),
        ),
        _ConfirmSheetButtonStyle.destructive => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(_height),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          child: Text(label, style: labelStyle),
        ),
      },
    );
  }
}

class MomentDialog {
  const MomentDialog._();

  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
