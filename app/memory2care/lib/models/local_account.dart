import 'package:memory2care/models/user_profile.dart';

class LocalAccount {
  LocalAccount({
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    required this.profile,
    this.legacyPassword,
  });

  final String email;
  final String? passwordHash;
  final String? passwordSalt;
  final String? legacyPassword;
  final UserProfile profile;

  static const noChange = Object();

  LocalAccount copyWith({
    String? email,
    String? passwordHash,
    String? passwordSalt,
    Object? legacyPassword = noChange,
    UserProfile? profile,
  }) {
    return LocalAccount(
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      legacyPassword:
          identical(legacyPassword, noChange)
              ? this.legacyPassword
              : legacyPassword as String?,
      profile: profile ?? this.profile,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'passwordHash': passwordHash,
      'passwordSalt': passwordSalt,
      'profile': profile.toMap(),
    };
  }

  static LocalAccount fromMap(Map<String, dynamic> map) {
    return LocalAccount(
      email: map['email'] as String,
      passwordHash: map['passwordHash'] as String?,
      passwordSalt: map['passwordSalt'] as String?,
      legacyPassword: map['password'] as String?,
      profile: UserProfile.fromMap(map['profile'] as Map<String, dynamic>),
    );
  }
}
