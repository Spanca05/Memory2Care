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
  static const _tokenKey = 'auth_token';
  static const _localAccountKey = 'local_account';

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

  Future<void> saveProfile(UserProfile profile) {
    return _prefs.setString(_profileKey, jsonEncode(profile.toMap()));
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

  Future<void> saveAuthToken(String token) {
    return _prefs.setString(_tokenKey, token);
  }

  Future<void> clearAuthToken() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_profileKey);
  }

  LocalAccount? readLocalAccount() {
    final raw = _prefs.getString(_localAccountKey);
    if (raw == null) {
      return null;
    }
    return LocalAccount.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveLocalAccount(LocalAccount account) {
    return _prefs.setString(_localAccountKey, jsonEncode(account.toMap()));
  }
}
