import 'package:flutter/material.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/screens/auth/phone_number_screen.dart';
import 'package:memory2care/utils/snackbar.dart';
import 'package:memory2care/utils/validators.dart';
import 'package:memory2care/widgets/form_text_field.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    final result = await widget.controller.register(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    if (!result.success) {
      showSnack(context, result.message ?? 'Registration failed');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhoneNumberScreen(controller: widget.controller),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Create your\naccount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 44,
                    height: 1.04,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 30),
                FormTextField(
                  controller: _nameCtrl,
                  icon: Icons.person_outline,
                  hint: 'Full Name',
                  validator: (value) => requiredField(value, 'Full name'),
                ),
                const SizedBox(height: 14),
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
                  validator: validatePassword,
                ),
                const SizedBox(height: 14),
                FormTextField(
                  controller: _confirmPasswordCtrl,
                  icon: Icons.lock_outline,
                  hint: 'Confirm Password',
                  obscured: true,
                  validator: (value) {
                    final message = validatePassword(value);
                    if (message != null) {
                      return message;
                    }
                    if (value != _passwordCtrl.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child:
                      _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Register'),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already Have An Account? ',
                      style: TextStyle(color: muted),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Sign In',
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
