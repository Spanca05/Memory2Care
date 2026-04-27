import 'package:flutter/material.dart';

class FormTextField extends StatefulWidget {
  const FormTextField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    this.validator,
    this.obscured = false,
    this.keyboardType,
    this.toggleObscureText = false,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final String? Function(String?)? validator;
  final bool obscured;
  final TextInputType? keyboardType;
  final bool toggleObscureText;

  @override
  State<FormTextField> createState() => _FormTextFieldState();
}

class _FormTextFieldState extends State<FormTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscured;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _isObscured,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      decoration: InputDecoration(
        prefixIcon: Icon(widget.icon, color: Colors.grey.shade500),
        suffixIcon:
            widget.toggleObscureText && widget.obscured
                ? IconButton(
                  onPressed: () {
                    setState(() => _isObscured = !_isObscured);
                  },
                  icon: Icon(
                    _isObscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                  ),
                )
                : widget.obscured
                ? Icon(
                  Icons.visibility_off_outlined,
                  color: Colors.grey.shade400,
                )
                : null,
        hintText: widget.hint,
      ),
    );
  }
}
