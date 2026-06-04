class UserProfile {
  UserProfile({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.birthDate,
  });

  final String fullName;
  final String email;
  final String phone;
  final String gender;
  final DateTime birthDate;

  String get username {
    final seed = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return '@$seed';
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? gender,
    DateTime? birthDate,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'gender': gender,
      'birthDate': birthDate.toIso8601String(),
    };
  }

  static UserProfile fromMap(Map<String, dynamic> map) {
    return UserProfile(
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      gender: map['gender'] as String,
      birthDate: DateTime.parse(map['birthDate'] as String),
    );
  }
}
