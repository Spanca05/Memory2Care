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
                  child: Text(
                    'Forget Password ?',
                    style: TextStyle(color: muted),
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
