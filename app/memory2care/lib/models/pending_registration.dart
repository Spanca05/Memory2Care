class PendingRegistration {
  PendingRegistration({
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
  });

  final String fullName;
  final String email;
  final String passwordHash;
  final String passwordSalt;
}
