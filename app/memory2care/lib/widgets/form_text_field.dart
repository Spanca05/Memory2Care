import 'package:flutter/material.dart';

class FormTextField extends StatelessWidget {
  const FormTextField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    this.validator,
    this.obscured = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final String? Function(String?)? validator;
  final bool obscured;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscured,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        suffixIcon:
            obscured
                ? Icon(
                  Icons.visibility_off_outlined,
                  color: Colors.grey.shade400,
                )
                : null,
        hintText: hint,
      ),
    );
  }
}
