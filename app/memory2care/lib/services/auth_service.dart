import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:memory2care/models/auth_result.dart';
import 'package:memory2care/models/local_account.dart';
import 'package:memory2care/models/pending_registration.dart';
import 'package:memory2care/models/user_profile.dart';
import 'package:memory2care/services/local_store.dart';
import 'package:memory2care/utils/security.dart';

class AuthService {
  AuthService({required this.baseUrl});

  final String baseUrl;
  PendingRegistration? _pending;

  bool get _hasRemote => baseUrl.trim().isNotEmpty;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (_hasRemote) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final payload = jsonDecode(response.body) as Map<String, dynamic>;
          final user = UserProfile(
            fullName: payload['fullName'] as String? ?? 'Memory2Care User',
            email: payload['email'] as String? ?? email,
            phone: payload['phone'] as String? ?? '',
            gender: payload['gender'] as String? ?? 'Prefer not to say',
            birthDate:
                DateTime.tryParse(payload['birthDate'] as String? ?? '') ??
                DateTime(2000, 1, 1),
          );

          return AuthResult(
            success: true,
            user: user,
            token: payload['token'] as String? ?? 'remote-token',
          );
        }
      } catch (_) {}
    }

    final local = await LocalStore.instance();
    final account = local.readLocalAccountByEmail(email);
    if (account == null) {
      return AuthResult(
        success: false,
        message: 'No account found. Please create an account first.',
      );
    }

    final emailMatches = account.email.toLowerCase() == email.toLowerCase();
    final hashMatches =
        account.passwordHash != null &&
        account.passwordSalt != null &&
        verifyPassword(
          password: password,
          salt: account.passwordSalt!,
          expectedHash: account.passwordHash!,
        );
    final legacyMatches = account.legacyPassword == password;

    if (!emailMatches || (!hashMatches && !legacyMatches)) {
      return AuthResult(success: false, message: 'Invalid email or password.');
    }

    if (legacyMatches && !hashMatches) {
      final salt = generateSalt();
      final hash = hashPassword(password: password, salt: salt);
      await local.upsertLocalAccount(
        account.copyWith(
          passwordHash: hash,
          passwordSalt: salt,
          legacyPassword: null,
        ),
      );
    }

    await local.setActiveAccountEmail(account.email);

    return AuthResult(
      success: true,
      user: account.profile,
      token: 'local-token',
    );
  }

  Future<AuthResult> startRegistration({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (_hasRemote) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fullName': fullName,
            'email': email,
            'password': password,
          }),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final salt = generateSalt();
          final hash = hashPassword(password: password, salt: salt);
          _pending = PendingRegistration(
            fullName: fullName,
            email: email,
            passwordHash: hash,
            passwordSalt: salt,
          );
          return AuthResult(success: true);
        }
      } catch (_) {}
    }

    final local = await LocalStore.instance();
    if (local.readLocalAccountByEmail(email) != null) {
      return AuthResult(
        success: false,
        message: 'An account with this email already exists.',
      );
    }

    final salt = generateSalt();
    final hash = hashPassword(password: password, salt: salt);
    _pending = PendingRegistration(
      fullName: fullName,
      email: email,
      passwordHash: hash,
      passwordSalt: salt,
    );
    return AuthResult(success: true);
  }

  Future<AuthResult> completeRegistration({
    required String phone,
    required String otpCode,
  }) async {
    if (_pending == null) {
      return AuthResult(
        success: false,
        message: 'Registration session expired. Please try again.',
      );
    }

    if (otpCode.length != 4) {
      return AuthResult(
        success: false,
        message: 'Verification code must have 4 digits.',
      );
    }

    if (_hasRemote) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/verify'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _pending!.email,
            'otp': otpCode,
            'phone': phone,
          }),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final payload = jsonDecode(response.body) as Map<String, dynamic>;
          final user = UserProfile(
            fullName: payload['fullName'] as String? ?? _pending!.fullName,
            email: payload['email'] as String? ?? _pending!.email,
            phone: payload['phone'] as String? ?? phone,
            gender: payload['gender'] as String? ?? 'Prefer not to say',
            birthDate:
                DateTime.tryParse(payload['birthDate'] as String? ?? '') ??
                DateTime(2000, 1, 1),
          );
          _pending = null;
          return AuthResult(
            success: true,
            user: user,
            token: payload['token'] as String? ?? 'remote-token',
          );
        }
      } catch (_) {}
    }

    final user = UserProfile(
      fullName: _pending!.fullName,
      email: _pending!.email,
      phone: phone,
      gender: 'Prefer not to say',
      birthDate: DateTime(2000, 1, 1),
    );

    final local = await LocalStore.instance();
    await local.upsertLocalAccount(
      LocalAccount(
        email: _pending!.email,
        passwordHash: _pending!.passwordHash,
        passwordSalt: _pending!.passwordSalt,
        profile: user,
      ),
    );
    await local.setActiveAccountEmail(user.email);
    _pending = null;
    return AuthResult(success: true, user: user, token: 'local-token');
  }

  Future<AuthResult> resetPassword({
    required String email,
    required String phone,
    required String newPassword,
  }) async {
    if (_hasRemote) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/reset-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'phone': phone,
            'newPassword': newPassword,
          }),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return AuthResult(success: true);
        }
      } catch (_) {}
    }

    final local = await LocalStore.instance();
    final account = local.readLocalAccountByEmail(email);
    if (account == null) {
      return AuthResult(
        success: false,
        message: 'No account found with this email.',
      );
    }

    final normalizedPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final accountPhone = account.profile.phone.replaceAll(RegExp(r'\s+'), '');
    if (accountPhone != normalizedPhone) {
      return AuthResult(
        success: false,
        message: 'Phone number does not match this account.',
      );
    }

    final salt = generateSalt();
    final hash = hashPassword(password: newPassword, salt: salt);

    await local.upsertLocalAccount(
      account.copyWith(
        passwordHash: hash,
        passwordSalt: salt,
        legacyPassword: null,
      ),
    );

    return AuthResult(success: true);
  }
}
