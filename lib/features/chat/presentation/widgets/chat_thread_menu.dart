import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/widgets/moment_button.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/core/widgets/moment_controls.dart';
import 'package:moment/features/friends/domain/entities/friend_entities.dart';
import 'package:moment/features/friends/domain/repositories/friends_repository.dart';
import 'package:moment/features/friends/presentation/cubit/friends_cubit.dart';
import 'package:moment/features/profile/domain/entities/user_profile.dart';
import 'package:moment/features/settings/presentation/widgets/settings_type.dart';

enum ChatThreadMenuAction { viewProfile, block, unblock, report }

Future<ChatThreadMenuAction?> showChatThreadMenu(
  BuildContext context,
  UserProfile user, {
  required FriendRelationship relationship,
}) {
  final isBlockedByMe = relationship == FriendRelationship.blocked;

  return showModalBottomSheet<ChatThreadMenuAction>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuTile(
                icon: Icons.person_outline_rounded,
                label: 'View profile',
                onTap: () =>
                    Navigator.pop(context, ChatThreadMenuAction.viewProfile),
              ),
              _MenuTile(
                icon: isBlockedByMe
                    ? Icons.lock_open_rounded
                    : Icons.block_rounded,
                label: isBlockedByMe ? 'Unblock' : 'Block',
                destructive: !isBlockedByMe,
                onTap: () => Navigator.pop(
                  context,
                  isBlockedByMe
                      ? ChatThreadMenuAction.unblock
                      : ChatThreadMenuAction.block,
                ),
              ),
              _MenuTile(
                icon: Icons.flag_outlined,
                label: 'Report',
                destructive: true,
                onTap: () =>
                    Navigator.pop(context, ChatThreadMenuAction.report),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> handleChatThreadMenuAction({
  required BuildContext context,
  required UserProfile user,
  required ChatThreadMenuAction action,
  Future<void> Function()? onBlock,
  Future<void> Function()? onUnblock,
  VoidCallback? onReported,
}) async {
  switch (action) {
    case ChatThreadMenuAction.viewProfile:
      if (context.mounted) context.push(AppRoutes.friend(user.id));
    case ChatThreadMenuAction.block:
      final ok = await MomentDialog.confirm(
        context,
        title: 'Block ${user.displayName}?',
        message: 'They cannot send you messages or friend requests.',
        confirmLabel: 'Block',
      );
      if (ok == true && context.mounted) {
        if (onBlock != null) {
          await onBlock();
        } else {
          final result = await sl<FriendsRepository>().blockUser(user.id);
          if (!context.mounted) return;
          if (result is Success) {
            context.pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.failureOrNull?.message ?? 'Could not block user',
                ),
              ),
            );
          }
        }
      }
    case ChatThreadMenuAction.unblock:
      final ok = await MomentDialog.confirm(
        context,
        title: 'Unblock ${user.displayName}?',
        message:
            'They will be able to send you friend requests and messages again.',
        confirmLabel: 'Unblock',
      );
      if (ok == true && context.mounted) {
        if (onUnblock != null) {
          await onUnblock();
        } else {
          final result = await sl<FriendsRepository>().unblockUser(user.id);
          if (!context.mounted) return;
          if (result is! Success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.failureOrNull?.message ?? 'Could not unblock user',
                ),
              ),
            );
          }
        }
      }
    case ChatThreadMenuAction.report:
      if (context.mounted) {
        await _showReportSheet(
          context,
          user.id,
          onReported: onReported,
        );
      }
  }
}

Future<void> _showReportSheet(
  BuildContext context,
  String userId, {
  VoidCallback? onReported,
}) async {
  const reasons = ['Spam', 'Harassment', 'Inappropriate content', 'Other'];
  var selected = reasons.first;
  final detailsController = TextEditingController();
  var isSubmitting = false;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Report user',
                  style: SettingsType.title(
                    AppColors.textPrimaryDark,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: AppSpacing.md),
                ...reasons.map(
                  (reason) => AbsorbPointer(
                    absorbing: isSubmitting,
                    child: MomentRadioRow<String>(
                      label: reason,
                      value: reason,
                      groupValue: selected,
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selected = value);
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: detailsController,
                  enabled: !isSubmitting,
                  style: SettingsType.body(AppColors.textPrimaryDark),
                  decoration: InputDecoration(
                    labelText: 'Details (optional)',
                    labelStyle: SettingsType.caption(
                      AppColors.textTertiaryDark,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceElevatedDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: AppSpacing.lg),
                MomentButton(
                  label: 'Submit report',
                  isLoading: isSubmitting,
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setSheetState(() => isSubmitting = true);
                          final cubit = context.read<FriendsCubit?>();
                          if (cubit != null) {
                            await cubit.reportUser(
                              userId,
                              selected,
                              details: detailsController.text,
                            );
                          } else {
                            await sl<FriendsRepository>().reportUser(
                              userId: userId,
                              reason: selected,
                              details: detailsController.text.trim().isEmpty
                                  ? null
                                  : detailsController.text.trim(),
                            );
                          }
                          if (context.mounted) {
                            Navigator.of(sheetContext).pop();
                            onReported?.call();
                          }
                        },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  detailsController.dispose();
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFFF6B6B)
        : AppColors.textPrimaryDark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
