import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voxmatrix/core/constants/app_constants.dart';
import 'package:voxmatrix/core/constants/app_strings.dart';
import 'package:voxmatrix/core/theme/app_colors.dart';
import 'package:voxmatrix/core/utils/validators.dart';
import 'package:voxmatrix/presentation/auth/bloc/auth_bloc.dart';
import 'package:voxmatrix/presentation/auth/bloc/auth_event.dart';
import 'package:voxmatrix/presentation/auth/bloc/auth_state.dart';
import 'package:voxmatrix/presentation/auth/pages/register_page.dart';
import 'package:voxmatrix/presentation/home/home_page.dart';
import 'package:voxmatrix/presentation/widgets/glass_container.dart';
import 'package:voxmatrix/presentation/widgets/glass_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _homeserverController = TextEditingController(
    text: AppConstants.defaultHomeserver,
  );
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _homeserverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginRequested(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
              homeserver: _homeserverController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassScaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
                showCloseIcon: true,
                backgroundColor: AppColors.error.withOpacity(0.9),
              ),
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: GlassContainer(
                  opacity: 0.12,
                  blur: 15,
                  borderRadius: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo/Icon
                        Center(
                          child: GlassContainer(
                            width: 80,
                            height: 80,
                            borderRadius: 24,
                            color: AppColors.primary,
                            opacity: 0.2,
                            blur: 5,
                            child: const Center(
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          AppStrings.loginTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          AppStrings.loginSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Homeserver field
                        _buildFieldLabel('Homeserver'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _homeserverController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'e.g., matrix.org',
                            prefixIcon: const Icon(Icons.dns_rounded, size: 20),
                          ),
                          validator: Validators.validateHomeserver,
                        ),
                        const SizedBox(height: 20),

                        // Username field
                        _buildFieldLabel('Username'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'your_username',
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                          ),
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          validator: Validators.validateUsername,
                        ),
                        const SizedBox(height: 20),

                        // Password field
                        _buildFieldLabel('Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          validator: Validators.validatePassword,
                          onFieldSubmitted: (_) => _onLoginPressed(),
                        ),
                        const SizedBox(height: 12),

                        // Remember me row
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                side: const BorderSide(color: AppColors.glassBorder, width: 1.5),
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rememberMe = !_rememberMe;
                                });
                              },
                              child: Text(
                                AppStrings.rememberMe,
                                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Login button
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;
                            return Container(
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.red.shade900,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _onLoginPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.black,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Text('Login', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.noAccount,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                );
                              },
                              child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}
