import 'package:flutter/material.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/screens/main/main_shell.dart';
import 'package:memory2care/utils/snackbar.dart';

class VerifyNumberScreen extends StatefulWidget {
  const VerifyNumberScreen({
    super.key,
    required this.controller,
    required this.phoneNumber,
  });

  final AppController controller;
  final String phoneNumber;

  @override
  State<VerifyNumberScreen> createState() => _VerifyNumberScreenState();
}

class _VerifyNumberScreenState extends State<VerifyNumberScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otpCtrl.text.trim().length != 4) {
      showSnack(context, 'Please enter the 4-digit code');
      return;
    }

    setState(() => _loading = true);
    final result = await widget.controller.completeRegistration(
      phone: widget.phoneNumber,
      otpCode: _otpCtrl.text.trim(),
    );
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    if (!result.success) {
      showSnack(context, result.message ?? 'Verification failed');
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
    final muted = Colors.grey.shade500;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(backgroundColor: Colors.white),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Verify Phone Number',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We Have Sent Code To Your Phone Number',
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.phoneNumber,
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        hintText: 'Enter 4-digit code',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _verify,
                      child:
                          _loading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text('Verify'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        showSnack(context, 'A new code has been sent');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE3E5EA),
                        foregroundColor: const Color(0xFF9FA4B1),
                      ),
                      child: const Text('Send Again'),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
