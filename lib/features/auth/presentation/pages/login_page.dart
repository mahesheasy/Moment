import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moment/app/di/injection.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/theme/app_spacing.dart';
import 'package:moment/core/theme/moment_theme.dart';
import 'package:moment/core/widgets/moment_sheet_dialog.dart';
import 'package:moment/features/auth/domain/validators/auth_validators.dart';
import 'package:moment/features/auth/presentation/cubit/auth_form_cubit.dart';
import 'package:moment/features/auth/presentation/widgets/auth_chrome.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginCubit>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSocialTap(AuthSocialProvider provider) {
    final label = switch (provider) {
      AuthSocialProvider.google => 'Google',
      AuthSocialProvider.apple => 'Apple',
      AuthSocialProvider.facebook => 'Facebook',
    };
    showAuthComingSoon(context, label);
  }

  void _submitLogin() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<LoginCubit>().submit(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;

    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.status == AuthFormStatus.success) {
          context.go(AppRoutes.home);
        }
        if (state.errorMessage != null &&
            state.status == AuthFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.infoMessage != null &&
            state.status == AuthFormStatus.emailSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.infoMessage!)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: mc.background,
        body: AuthAmbientBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const SizedBox(height: AppSpacing.huge),
                  const Center(child: AuthLogoMark()),
                  const SizedBox(height: AppSpacing.xxxl),
                  Text(
                    'Welcome back.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: mc.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sign in to see your moments.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: mc.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.massive),
                  AuthTextField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: AuthValidators.emailField,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AuthTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitLogin(),
                    validator: AuthValidators.passwordField,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showResetPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: mc.accent,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: mc.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  BlocBuilder<LoginCubit, LoginState>(
                    builder: (context, state) {
                      return AuthGradientButton(
                        label: 'Sign in',
                        isLoading: state.status == AuthFormStatus.loading,
                        onPressed: state.status == AuthFormStatus.loading
                            ? null
                            : _submitLogin,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  const AuthOrDivider(),
                  const SizedBox(height: AppSpacing.xxl),
                  AuthSocialRow(onTap: _onSocialTap),
                  const SizedBox(height: AppSpacing.xxxl),
                  _AuthFooterLink(
                    prefix: "Don't have an account? ",
                    action: 'Create account',
                    onTap: () => context.go(AppRoutes.register),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showResetPassword() async {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController(text: _emailController.text);
    await MomentBottomSheet.show<void>(
      context,
      title: 'Reset password',
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: emailController,
              hint: 'Email',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: AuthValidators.emailField,
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthGradientButton(
              label: 'Send reset link',
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                context.read<LoginCubit>().sendPasswordReset(
                  emailController.text,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
    emailController.dispose();
  }
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RegisterCubit>(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _onSocialTap(AuthSocialProvider provider) {
    final label = switch (provider) {
      AuthSocialProvider.google => 'Google',
      AuthSocialProvider.apple => 'Apple',
      AuthSocialProvider.facebook => 'Facebook',
    };
    showAuthComingSoon(context, label);
  }

  void _submitRegister() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<RegisterCubit>().submit(
      email: _emailController.text,
      password: _passwordController.text,
      username: _usernameController.text,
      displayName: _displayNameController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;

    return BlocListener<RegisterCubit, RegisterState>(
      listener: (context, state) {
        if (state.status == AuthFormStatus.success) {
          context.go(AppRoutes.home);
        }
        if (state.status == AuthFormStatus.emailSent &&
            state.infoMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.infoMessage!)),
          );
          context.go(AppRoutes.login);
        }
        if (state.errorMessage != null &&
            state.status == AuthFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: mc.background,
        body: AuthAmbientBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const SizedBox(height: AppSpacing.sm),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AuthBackButton(),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: mc.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 30,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                      children: [
                        const TextSpan(text: 'Join '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: AuthGradientText(
                            text: 'Moment.',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Private moments with your closest people.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: mc.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  AuthTextField(
                    controller: _displayNameController,
                    hint: 'Display name',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: AuthValidators.displayNameField,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AuthTextField(
                    controller: _usernameController,
                    hint: 'Username',
                    icon: Icons.alternate_email_rounded,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    validator: AuthValidators.usernameField,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AuthTextField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: AuthValidators.emailField,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AuthTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitRegister(),
                    validator: AuthValidators.passwordField,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  BlocBuilder<RegisterCubit, RegisterState>(
                    builder: (context, state) {
                      return AuthGradientButton(
                        label: 'Create account',
                        isLoading: state.status == AuthFormStatus.loading,
                        onPressed: state.status == AuthFormStatus.loading
                            ? null
                            : _submitRegister,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _TermsText(accent: mc.accent, secondary: mc.textTertiary),
                  const SizedBox(height: AppSpacing.xxxl),
                  const AuthOrDivider(),
                  const SizedBox(height: AppSpacing.xxl),
                  AuthSocialRow(onTap: _onSocialTap),
                  const SizedBox(height: AppSpacing.xxxl),
                  _AuthFooterLink(
                    prefix: 'Already have an account? ',
                    action: 'Sign in',
                    onTap: () => context.go(AppRoutes.login),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText({required this.accent, required this.secondary});

  final Color accent;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(color: secondary, fontSize: 11, height: 1.45),
        children: [
          const TextSpan(text: 'By creating an account, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: TextStyle(color: accent, fontWeight: FontWeight.w500),
            recognizer: TapGestureRecognizer()
              ..onTap = () => showAuthComingSoon(context, 'Terms'),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(color: accent, fontWeight: FontWeight.w500),
            recognizer: TapGestureRecognizer()
              ..onTap = () => showAuthComingSoon(context, 'Privacy'),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _AuthFooterLink extends StatelessWidget {
  const _AuthFooterLink({
    required this.prefix,
    required this.action,
    required this.onTap,
  });

  final String prefix;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return Center(
      child: Text.rich(
        TextSpan(
          style: TextStyle(color: mc.textSecondary, fontSize: 13),
          children: [
            TextSpan(text: prefix),
            TextSpan(
              text: action,
              style: TextStyle(
                color: mc.accent,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()..onTap = onTap,
            ),
          ],
        ),
      ),
    );
  }
}
