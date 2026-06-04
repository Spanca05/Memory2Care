import 'package:memory2care/models/user_profile.dart';

class AuthResult {
  AuthResult({required this.success, this.message, this.user, this.token});

  final bool success;
  final String? message;
  final UserProfile? user;
  final String? token;
}
