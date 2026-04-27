import 'package:flutter/material.dart';
import 'package:memory2care/models/auth_result.dart';
import 'package:memory2care/models/medication_plan.dart';
import 'package:memory2care/models/user_profile.dart';
import 'package:memory2care/services/auth_service.dart';
import 'package:memory2care/services/local_store.dart';

class AppController extends ChangeNotifier {
  AppController({required this.authService});

  final AuthService authService;
  bool _isInitialized = false;
  UserProfile? _currentUser;
  MedicationPlan _medicationPlan = MedicationPlan.defaultPlan();
  final Set<DateTime> _takenDates = <DateTime>{};
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool get isInitialized => _isInitialized;
  UserProfile? get currentUser => _currentUser;
  MedicationPlan get medicationPlan => _medicationPlan;
  DateTime get focusedMonth => _focusedMonth;

  Future<void> initialize() async {
    final local = await LocalStore.instance();
    _currentUser = local.readProfile();
    _medicationPlan =
        local.readMedicationPlan() ?? MedicationPlan.defaultPlan();
    _takenDates
      ..clear()
      ..addAll(local.readTakenDates());
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
    await local.saveProfile(result.user!);
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
    await local.saveProfile(result.user!);
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
    await local.saveProfile(updated);
    notifyListeners();
  }

  Future<void> updateMedicationPlan(MedicationPlan plan) async {
    _medicationPlan = plan;
    final local = await LocalStore.instance();
    await local.saveMedicationPlan(plan);
    notifyListeners();
  }

  bool isDueDate(DateTime date) {
    final normalized = _normalizeDate(date);
    return _medicationPlan.isDueOn(normalized);
  }

  bool isTaken(DateTime date) {
    return _takenDates.contains(_normalizeDate(date));
  }

  Future<void> toggleTaken(DateTime date) async {
    final normalized = _normalizeDate(date);
    if (!isDueDate(normalized)) {
      return;
    }

    if (_takenDates.contains(normalized)) {
      _takenDates.remove(normalized);
    } else {
      _takenDates.add(normalized);
    }

    final local = await LocalStore.instance();
    await local.saveTakenDates(_takenDates);
    notifyListeners();
  }

  void setFocusedMonth(DateTime month) {
    _focusedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
