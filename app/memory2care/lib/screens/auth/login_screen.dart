import 'package:flutter/material.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/screens/auth/create_account_screen.dart';
import 'package:memory2care/screens/main/main_shell.dart';
import 'package:memory2care/utils/snackbar.dart';
import 'package:memory2care/utils/validators.dart';
import 'package:memory2care/widgets/form_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    final result = await widget.controller.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    if (!result.success) {
      showSnack(context, result.message ?? 'Login failed');
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainShell(controller: widget.controller),
      ),
    );
  }

  Future<void> _openResetPasswordDialog() async {
    final dialogFormKey = GlobalKey<FormState>();
    final resetEmailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final resetPhoneCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    var loading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            Future<void> submitReset() async {
              if (!dialogFormKey.currentState!.validate()) {
                return;
              }

              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);

              setDialogState(() => loading = true);
              try {
                final result = await widget.controller.resetPassword(
                  email: resetEmailCtrl.text.trim(),
                  phone: resetPhoneCtrl.text.trim(),
                  newPassword: newPasswordCtrl.text,
                );
                if (!mounted || !dialogContext.mounted) {
                  return;
                }
                setDialogState(() => loading = false);

                if (!result.success) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(result.message ?? 'Unable to reset password'),
                    ),
                  );
                  return;
                }

                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Password updated. You can now log in.'),
                  ),
                );
              } catch (_) {
                if (!mounted || !dialogContext.mounted) {
                  return;
                }
                setDialogState(() => loading = false);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Unexpected error while resetting password.'),
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('Reset Password'),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FormTextField(
                      controller: resetEmailCtrl,
                      icon: Icons.mail_outline,
                      hint: 'Email',
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 12),
                    FormTextField(
                      controller: resetPhoneCtrl,
                      icon: Icons.phone_outlined,
                      hint: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      validator: validatePhone,
                    ),
                    const SizedBox(height: 12),
                    FormTextField(
                      controller: newPasswordCtrl,
                      icon: Icons.lock_outline,
                      hint: 'New Password',
                      obscured: true,
                      toggleObscureText: true,
                      validator: validatePassword,
                    ),
                    const SizedBox(height: 12),
                    FormTextField(
                      controller: confirmPasswordCtrl,
                      icon: Icons.lock_outline,
                      hint: 'Confirm New Password',
                      obscured: true,
                      toggleObscureText: true,
                      validator: (value) {
                        final required = requiredField(
                          value,
                          'Confirm new password',
                        );
                        if (required != null) {
                          return required;
                        }
                        if (value != newPasswordCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      loading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: loading ? null : submitReset,
                  child:
                      loading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Reset'),
                ),
              ],
            );
          },
        );
      },
    );

  }

  @override
  Widget build(BuildContext context) {
    final muted = Colors.grey.shade500;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Spacer(),
                const Text(
                  'Login',
                  style: TextStyle(fontSize: 46, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 34),
                FormTextField(
                  controller: _emailCtrl,
                  icon: Icons.mail_outline,
                  hint: 'Enter Your Email',
                  validator: validateEmail,
                ),
                const SizedBox(height: 14),
                FormTextField(
                  controller: _passwordCtrl,
                  icon: Icons.lock_outline,
                  hint: 'Password',
                  obscured: true,
                  toggleObscureText: true,
                  validator: validatePassword,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _loading ? null : _openResetPasswordDialog,
                    child: Text(
                      'Forget Password ?',
                      style: TextStyle(color: muted),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child:
                      _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login'),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create New Account? ',
                      style: TextStyle(color: muted),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => CreateAccountScreen(
                                  controller: widget.controller,
                                ),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign up',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
