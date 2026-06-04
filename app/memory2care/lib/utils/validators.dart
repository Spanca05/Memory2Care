String? requiredField(String? value, String label) {
  if (value == null || value.trim().isEmpty) {
    return '$label is required';
  }
  return null;
}

String? validateEmail(String? value) {
  final requiredError = requiredField(value, 'Email');
  if (requiredError != null) {
    return requiredError;
  }

  final email = value!.trim();
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailRegex.hasMatch(email)) {
    return 'Invalid email format';
  }
  return null;
}

String? validatePassword(String? value) {
  final requiredError = requiredField(value, 'Password');
  if (requiredError != null) {
    return requiredError;
  }

  if (value!.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}

String? validatePhone(String? value) {
  final requiredError = requiredField(value, 'Phone number');
  if (requiredError != null) {
    return requiredError;
  }

  final phone = value!.replaceAll(RegExp(r'\s+'), '');
  final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
  if (!phoneRegex.hasMatch(phone)) {
    return 'Invalid phone number';
  }
  return null;
}
