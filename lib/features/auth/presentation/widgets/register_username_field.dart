import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/moment_colors.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/features/auth/domain/validators/auth_validators.dart';
import 'package:moment/features/auth/presentation/cubit/username_field_cubit.dart';
import 'package:moment/features/auth/presentation/widgets/username_create_sheet.dart';

class RegisterUsernameField extends StatefulWidget {
  const RegisterUsernameField({
    required this.controller,
    required this.displayNameController,
    super.key,
  });

  final TextEditingController controller;
  final TextEditingController displayNameController;

  @override
  State<RegisterUsernameField> createState() => _RegisterUsernameFieldState();
}

class _RegisterUsernameFieldState extends State<RegisterUsernameField> {
  var _ignoreNextChange = false;

  void _applyUsername(String username) {
    _ignoreNextChange = true;
    widget.controller.value = TextEditingValue(
      text: username,
      selection: TextSelection.collapsed(offset: username.length),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ignoreNextChange = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;

    return BlocBuilder<UsernameFieldCubit, UsernameFieldState>(
      builder: (context, state) {
        final borderColor = _borderColor(mc, state.status);
        final showStatus = state.hasTyped &&
            state.status != UsernameCheckStatus.idle &&
            state.status != UsernameCheckStatus.invalid;
        final isTaken = state.status == UsernameCheckStatus.taken;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: widget.controller,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                color: mc.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              cursorColor: mc.accent,
              validator: (value) {
                return AuthValidators.usernameField(value);
              },
              onChanged: (value) {
                if (_ignoreNextChange) return;
                context.read<UsernameFieldCubit>().onUsernameChanged(
                  rawValue: value,
                  displayName: widget.displayNameController.text,
                );
              },
              decoration: InputDecoration(
                hintText: 'Username',
                hintStyle: TextStyle(color: mc.textTertiary, fontSize: 14),
                prefixIcon: Icon(
                  Icons.alternate_email_rounded,
                  size: 18,
                  color: mc.textTertiary,
                ),
                suffixIcon: _suffixIcon(mc, state.status),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                filled: true,
                fillColor: mc.surface.withValues(alpha: 0.92),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isTaken || state.status == UsernameCheckStatus.error
                        ? mc.error.withValues(alpha: 0.75)
                        : state.status == UsernameCheckStatus.available
                        ? AppColors.success.withValues(alpha: 0.75)
                        : mc.accent.withValues(alpha: 0.55),
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: mc.error.withValues(alpha: 0.75),
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: mc.error),
                ),
              ),
            ),
            if (showStatus)
              _StatusSection(
                state: state,
                onUseSuggestion: (username) {
                  _applyUsername(username);
                  context.read<UsernameFieldCubit>().applySuggestion(
                    username,
                    widget.displayNameController.text,
                  );
                },
                onCreateOwn: () async {
                  final username = await showUsernameCreateSheet(context);
                  if (username == null || !context.mounted) return;
                  _applyUsername(username);
                  await context.read<UsernameFieldCubit>().applySuggestion(
                    username,
                    widget.displayNameController.text,
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget? _suffixIcon(MomentColors mc, UsernameCheckStatus status) {
    return switch (status) {
      UsernameCheckStatus.checking => _LoadingSuffix(color: mc.accent),
      UsernameCheckStatus.available => _IconSuffix(
        icon: Icons.check_circle_rounded,
        color: AppColors.success.withValues(alpha: 0.9),
      ),
      UsernameCheckStatus.taken || UsernameCheckStatus.error => _IconSuffix(
        icon: Icons.error_outline_rounded,
        color: mc.error.withValues(alpha: 0.9),
      ),
      _ => null,
    };
  }

  Color _borderColor(MomentColors mc, UsernameCheckStatus status) {
    return switch (status) {
      UsernameCheckStatus.available =>
        AppColors.success.withValues(alpha: 0.55),
      UsernameCheckStatus.taken || UsernameCheckStatus.error =>
        mc.error.withValues(alpha: 0.65),
      UsernameCheckStatus.checking =>
        mc.accent.withValues(alpha: 0.35),
      _ => mc.border.withValues(alpha: 0.35),
    };
  }
}

class _LoadingSuffix extends StatelessWidget {
  const _LoadingSuffix({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _IconSuffix extends StatelessWidget {
  const _IconSuffix({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.state,
    required this.onUseSuggestion,
    required this.onCreateOwn,
  });

  final UsernameFieldState state;
  final ValueChanged<String> onUseSuggestion;
  final VoidCallback onCreateOwn;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.status == UsernameCheckStatus.available)
            Text(
              'Username available',
              style: TextStyle(
                color: AppColors.success.withValues(alpha: 0.95),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          if (state.status == UsernameCheckStatus.error)
            Text(
              'Could not check username. Try again.',
              style: TextStyle(
                color: mc.error.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (state.status == UsernameCheckStatus.taken) ...[
            Text(
              'Username already taken',
              style: TextStyle(
                color: mc.error.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (state.suggestions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Try these:',
                style: TextStyle(
                  color: mc.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...state.suggestions.map(
                (username) => _SuggestionRow(
                  username: username,
                  onUse: () => onUseSuggestion(username),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            _CreateOwnRow(onTap: onCreateOwn),
          ],
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.username, required this.onUse});

  final String username;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: mc.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onUse,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mc.border.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '@$username',
                    style: TextStyle(
                      color: mc.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'Use',
                  style: TextStyle(
                    color: mc.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

class _CreateOwnRow extends StatelessWidget {
  const _CreateOwnRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_outlined,
              size: 14,
              color: mc.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Create your own',
              style: TextStyle(
                color: mc.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
