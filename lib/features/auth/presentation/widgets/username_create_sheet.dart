import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/auth/domain/validators/auth_validators.dart';
import 'package:moment/features/auth/presentation/widgets/auth_chrome.dart';

Future<String?> showUsernameCreateSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    builder: (sheetContext) {
      return const _UsernameCreateSheet();
    },
  );
}

class _UsernameCreateSheet extends StatefulWidget {
  const _UsernameCreateSheet();

  @override
  State<_UsernameCreateSheet> createState() => _UsernameCreateSheetState();
}

class _UsernameCreateSheetState extends State<_UsernameCreateSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    final error = AuthValidators.usernameField(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(
      AuthValidators.normalizeUsername(_controller.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: mc.surface.withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: mc.border.withValues(alpha: 0.35)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.md,
              AppSpacing.xxl,
              AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: mc.textTertiary.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Choose a username',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: mc.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _controller,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  style: TextStyle(color: mc.textPrimary, fontSize: 14),
                  cursorColor: mc.accent,
                  decoration: InputDecoration(
                    hintText: 'username',
                    hintStyle: TextStyle(color: mc.textTertiary, fontSize: 14),
                    prefixText: '@ ',
                    prefixStyle: TextStyle(
                      color: mc.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    errorText: _error,
                    errorStyle: TextStyle(color: mc.error, fontSize: 11),
                    filled: true,
                    fillColor: mc.background.withValues(alpha: 0.65),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: mc.border.withValues(alpha: 0.35),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: mc.border.withValues(alpha: 0.35),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: mc.accent.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onFieldSubmitted: (_) => _check(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Use letters, numbers and underscores',
                  style: TextStyle(color: mc.textTertiary, fontSize: 11),
                ),
                const SizedBox(height: AppSpacing.xl),
                AuthGradientButton(label: 'Check username', onPressed: _check),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: mc.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
