import 'package:flutter/material.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/screens/auth/verify_number_screen.dart';
import 'package:memory2care/screens/main/main_shell.dart';
import 'package:memory2care/utils/snackbar.dart';
import 'package:memory2care/utils/validators.dart';
import 'package:memory2care/widgets/form_text_field.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  bool _loadingLater = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => VerifyNumberScreen(
              controller: widget.controller,
              phoneNumber: _phoneCtrl.text.trim(),
            ),
      ),
    );
  }

  Future<void> _continueLater() async {
    setState(() => _loadingLater = true);

    final phone = _phoneCtrl.text.trim();
    final result = await widget.controller.completeRegistration(
      phone: phone.isEmpty ? 'Not provided' : phone,
      otpCode: '0000',
    );

    if (!mounted) {
      return;
    }

    setState(() => _loadingLater = false);

    if (!result.success) {
      showSnack(context, result.message ?? 'Could not complete registration');
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainShell(controller: widget.controller),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'Enter your phone\nnumber',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 44,
                    height: 1.04,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 30),
                FormTextField(
                  controller: _phoneCtrl,
                  icon: Icons.phone_outlined,
                  hint: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: validatePhone,
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _next,
                  child: const Text('Verification'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _loadingLater ? null : _continueLater,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE3E5EA),
                    foregroundColor: const Color(0xFF9FA4B1),
                  ),
                  child:
                      _loadingLater
                          ? const CircularProgressIndicator(
                            color: Color(0xFF9FA4B1),
                          )
                          : const Text('Later'),
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
