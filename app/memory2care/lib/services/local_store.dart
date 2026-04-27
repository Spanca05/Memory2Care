import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:memory2care/models/local_account.dart';
import 'package:memory2care/models/medication_plan.dart';
import 'package:memory2care/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore._(this._prefs);

  static const _profileKey = 'profile';
  static const _medicationKey = 'medication';
  static const _takenDatesKey = 'taken_dates';
  static const _takenMedicationsKey = 'taken_medications';
  static const _tokenKey = 'auth_token';
  static const _localAccountKey = 'local_account';
  static const _localAccountsKey = 'local_accounts';
  static const _activeAccountEmailKey = 'active_account_email';

  final SharedPreferences _prefs;

  static Future<LocalStore> instance() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStore._(prefs);
  }

  UserProfile? readProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) {
      return null;
    }
    return UserProfile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  UserProfile? readStoredUserProfile() {
    return readProfile() ?? readActiveLocalAccount()?.profile;
  }

  Future<void> saveProfile(UserProfile profile) {
    return _prefs.setString(_profileKey, jsonEncode(profile.toMap()));
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await saveProfile(profile);

    final account = readActiveLocalAccount();
    if (account == null) {
      return;
    }

    final oldEmail = account.email.toLowerCase();
    final newEmail = profile.email.toLowerCase();
    final updatedAccount = account.copyWith(
      email: profile.email,
      profile: profile,
    );

    if (oldEmail != newEmail) {
      final accounts = readLocalAccounts();
      accounts.remove(oldEmail);
      accounts[newEmail] = updatedAccount;
      await _prefs.setString(
        _localAccountsKey,
        jsonEncode(accounts.map((key, value) => MapEntry(key, value.toMap()))),
      );
      await _prefs.remove(_localAccountKey);
    } else {
      await upsertLocalAccount(updatedAccount);
    }

    await setActiveAccountEmail(profile.email);
  }

  MedicationPlan? readMedicationPlan() {
    final raw = _prefs.getString(_medicationKey);
    if (raw == null) {
      return null;
    }
    return MedicationPlan.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveMedicationPlan(MedicationPlan plan) {
    return _prefs.setString(_medicationKey, jsonEncode(plan.toMap()));
  }

  Set<DateTime> readTakenDates() {
    final raw = _prefs.getStringList(_takenDatesKey) ?? <String>[];
    return raw
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();
  }

  Future<void> saveTakenDates(Set<DateTime> dates) {
    final list = dates.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList();
    return _prefs.setStringList(_takenDatesKey, list);
  }

  Map<DateTime, Set<String>> readTakenMedicationsByDate() {
    final raw = _prefs.getString(_takenMedicationsKey);
    if (raw == null) {
      return <DateTime, Set<String>>{};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (dateStr, medicationIds) => MapEntry(
        DateTime.parse(dateStr),
        (medicationIds as List<dynamic>).map((e) => e as String).toSet(),
      ),
    );
  }

  Future<void> saveTakenMedicationsByDate(
    Map<DateTime, Set<String>> takenMeds,
  ) {
    final encoded = takenMeds.map(
      (date, medIds) =>
          MapEntry(DateFormat('yyyy-MM-dd').format(date), medIds.toList()),
    );
    return _prefs.setString(_takenMedicationsKey, jsonEncode(encoded));
  }

  Future<void> saveAuthToken(String token) {
    return _prefs.setString(_tokenKey, token);
  }

  Future<void> clearAuthToken() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_profileKey);
    await _prefs.remove(_activeAccountEmailKey);
  }

  LocalAccount? readLegacyLocalAccount() {
    final raw = _prefs.getString(_localAccountKey);
    if (raw == null) {
      return null;
    }
    return LocalAccount.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Map<String, LocalAccount> readLocalAccounts() {
    final raw = _prefs.getString(_localAccountsKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) =>
            MapEntry(key, LocalAccount.fromMap(value as Map<String, dynamic>)),
      );
    }

    final legacy = readLegacyLocalAccount();
    if (legacy == null) {
      return <String, LocalAccount>{};
    }

    return <String, LocalAccount>{legacy.email.toLowerCase(): legacy};
  }

  LocalAccount? readLocalAccountByEmail(String email) {
    return readLocalAccounts()[email.toLowerCase()];
  }

  LocalAccount? readActiveLocalAccount() {
    final activeEmail = readActiveAccountEmail();
    if (activeEmail == null || activeEmail.isEmpty) {
      return null;
    }
    return readLocalAccountByEmail(activeEmail);
  }

  String? readActiveAccountEmail() {
    return _prefs.getString(_activeAccountEmailKey);
  }

  Future<void> setActiveAccountEmail(String email) {
    return _prefs.setString(_activeAccountEmailKey, email.toLowerCase());
  }

  Future<void> upsertLocalAccount(LocalAccount account) async {
    final accounts = readLocalAccounts();
    final targetKey = account.email.toLowerCase();

    accounts[targetKey] = account;
    await _prefs.setString(
      _localAccountsKey,
      jsonEncode(accounts.map((key, value) => MapEntry(key, value.toMap()))),
    );
    await _prefs.remove(_localAccountKey);
  }
}
