import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/services/test_session_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _scenarioId = TestSessionPreferences.getScenarioId();
  String _methodValue = TestSessionPreferences.getMethodValue();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap wajib diisi';
    }
    return null;
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginWithNameEvent(fullName: _nameController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmailLoading = context.select<AuthBloc, bool>((bloc) {
      final state = bloc.state;
      return state is AuthLoading && state.isEmailLogin;
    });
    final isAnyLoading = context.select<AuthBloc, bool>(
      (bloc) => bloc.state is AuthLoading,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppToast.showError(context, state.message);
          } else if (state is AuthAuthenticated) {
            AppToast.showSuccess(
              context,
              'Selamat datang, ${state.user.name}!',
            );
            context.go(AppRoutes.homePath);
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo or App Name
                    const Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Masuk untuk Mulai Testing',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Cukup masukkan nama lengkap Anda',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 40),

                    // Test Session Selector
                    DropdownButtonFormField<String>(
                      initialValue: _scenarioId,
                      decoration: const InputDecoration(
                        labelText: 'Scenario',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'scenario_1',
                          child: Text('S1 - Search Jakarta'),
                        ),
                        DropdownMenuItem(
                          value: 'scenario_2',
                          child: Text('S2 - Filter WiFi + Pool'),
                        ),
                        DropdownMenuItem(
                          value: 'scenario_3',
                          child: Text('S3 - Booking'),
                        ),
                      ],
                      onChanged: isAnyLoading
                          ? null
                          : (value) async {
                              if (value == null) return;
                              setState(() {
                                _scenarioId = value;
                              });
                              await TestSessionPreferences.setScenarioId(value);
                            },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _methodValue,
                      decoration: const InputDecoration(
                        labelText: 'Method',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TestSessionPreferences.methodAuto,
                          child: Text('Auto (detect)'),
                        ),
                        DropdownMenuItem(
                          value: TestSessionPreferences.methodGui,
                          child: Text('GUI'),
                        ),
                        DropdownMenuItem(
                          value: TestSessionPreferences.methodVui,
                          child: Text('VUI'),
                        ),
                      ],
                      onChanged: isAnyLoading
                          ? null
                          : (value) async {
                              if (value == null) return;
                              setState(() {
                                _methodValue = value;
                              });
                              await TestSessionPreferences.setMethodValue(
                                value,
                              );
                            },
                    ),
                    const SizedBox(height: 24),

                    // Full Name Field
                    AuthTextField(
                      controller: _nameController,
                      label: 'Nama Lengkap',
                      hintText: 'Contoh: Ayu Lestari',
                      keyboardType: TextInputType.name,
                      validator: _validateName,
                      enabled: !isAnyLoading,
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    AuthButton(
                      text: 'Masuk',
                      onPressed: _handleLogin,
                      isLoading: isEmailLoading,
                    ),
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
