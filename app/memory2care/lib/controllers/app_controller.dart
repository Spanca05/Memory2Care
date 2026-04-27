import 'package:flutter/material.dart';
import 'package:memory2care/models/auth_result.dart';
import 'package:memory2care/models/medication.dart';
import 'package:memory2care/models/medication_plan.dart';
import 'package:memory2care/models/user_profile.dart';
import 'package:memory2care/services/auth_service.dart';
import 'package:memory2care/services/local_store.dart';

class AppController extends ChangeNotifier {
  AppController({required this.authService});

  final AuthService authService;
  bool _isInitialized = false;
  UserProfile? _currentUser;
  MedicationPlan _medicationPlan = MedicationPlan.empty();
  // Track taken medications as Map<date, Set<medicationId>>
  final Map<DateTime, Set<String>> _takenMedications =
      <DateTime, Set<String>>{};
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool get isInitialized => _isInitialized;
  UserProfile? get currentUser => _currentUser;
  MedicationPlan get medicationPlan => _medicationPlan;
  List<Medication> get medications => _medicationPlan.medications;
  DateTime get focusedMonth => _focusedMonth;

  Future<void> initialize() async {
    final local = await LocalStore.instance();
    _currentUser = local.readStoredUserProfile();
    _medicationPlan =
        local.readMedicationPlan() ?? MedicationPlan.defaultPlan();
    _takenMedications
      ..clear()
      ..addAll(local.readTakenMedicationsByDate());
    _isInitialized = true;
    notifyListeners();
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final result = await authService.login(email: email, password: password);
    if (!result.success || result.user == null) {
      return result;
    }

    _currentUser = result.user;
    final local = await LocalStore.instance();
    await local.saveUserProfile(result.user!);
    await local.saveAuthToken(result.token ?? 'local-token');
    notifyListeners();
    return result;
  }

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
  }) {
    return authService.startRegistration(
      fullName: fullName,
      email: email,
      password: password,
    );
  }

  Future<AuthResult> completeRegistration({
    required String phone,
    required String otpCode,
  }) async {
    final result = await authService.completeRegistration(
      phone: phone,
      otpCode: otpCode,
    );
    if (!result.success || result.user == null) {
      return result;
    }

    _currentUser = result.user;
    final local = await LocalStore.instance();
    await local.saveUserProfile(result.user!);
    await local.saveAuthToken(result.token ?? 'local-token');
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    _currentUser = null;
    final local = await LocalStore.instance();
    await local.clearAuthToken();
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile updated) async {
    _currentUser = updated;
    final local = await LocalStore.instance();
    await local.saveUserProfile(updated);
    notifyListeners();
  }

  Future<void> updateMedicationPlan(MedicationPlan plan) async {
    _medicationPlan = plan;
    final local = await LocalStore.instance();
    await local.saveMedicationPlan(plan);
    notifyListeners();
  }

  // Add a new medication to the plan
  Future<void> addMedication(Medication medication) async {
    final updated = _medicationPlan.copyWith(
      medications: [..._medicationPlan.medications, medication],
    );
    await updateMedicationPlan(updated);
  }

  // Update an existing medication
  Future<void> updateMedication(Medication medication) async {
    final updated = _medicationPlan.copyWith(
      medications:
          _medicationPlan.medications.map((m) {
            return m.id == medication.id ? medication : m;
          }).toList(),
    );
    await updateMedicationPlan(updated);
  }

  // Remove a medication from the plan
  Future<void> removeMedication(String medicationId) async {
    final updated = _medicationPlan.copyWith(
      medications:
          _medicationPlan.medications
              .where((m) => m.id != medicationId)
              .toList(),
    );
    await updateMedicationPlan(updated);
  }

  bool isDueDate(DateTime date) {
    final normalized = _normalizeDate(date);
    return _medicationPlan.getDueToday(normalized).isNotEmpty;
  }

  List<Medication> getDueMedicationsForDate(DateTime date) {
    final normalized = _normalizeDate(date);
    return _medicationPlan.getDueToday(normalized);
  }

  bool isMedicationTaken(String medicationId, DateTime date) {
    final normalized = _normalizeDate(date);
    return _takenMedications[normalized]?.contains(medicationId) ?? false;
  }

  int getTakenCountForDate(DateTime date) {
    final normalized = _normalizeDate(date);
    final dueMeds = getDueMedicationsForDate(normalized);
    final takenIds = _takenMedications[normalized] ?? {};
    return dueMeds.where((m) => takenIds.contains(m.id)).length;
  }

  Future<void> toggleMedicationTaken(String medicationId, DateTime date) async {
    final normalized = _normalizeDate(date);
    final medication = _medicationPlan.medications.firstWhere(
      (m) => m.id == medicationId,
    );

    if (!medication.isDueOn(normalized)) {
      return;
    }

    _takenMedications.putIfAbsent(normalized, () => {});
    final takenSet = _takenMedications[normalized]!;

    if (takenSet.contains(medicationId)) {
      takenSet.remove(medicationId);
    } else {
      takenSet.add(medicationId);
    }

    final local = await LocalStore.instance();
    await local.saveTakenMedicationsByDate(_takenMedications);
    notifyListeners();
  }

  void setFocusedMonth(DateTime month) {
    _focusedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
