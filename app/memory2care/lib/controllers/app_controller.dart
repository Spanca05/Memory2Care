import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:memory2care/models/auth_result.dart';
import 'package:memory2care/models/medication.dart';
import 'package:memory2care/models/medication_plan.dart';
import 'package:memory2care/models/user_profile.dart';
import 'package:memory2care/services/auth_service.dart';
import 'package:memory2care/services/local_store.dart';
import 'package:memory2care/services/notification_service.dart';

class AppController extends ChangeNotifier {
  AppController({required this.authService});

  final AuthService authService;
  late final NotificationService _notificationService;
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
    _notificationService = NotificationService();

    try {
      await _notificationService.initialize();
    } catch (_) {
      // Notification setup should never block the app bootstrap.
    }

    try {
      final local = await LocalStore.instance();
      await local.reloadActiveAccountState();
      _currentUser = local.readStoredUserProfile();
      _medicationPlan =
          local.readMedicationPlan() ?? MedicationPlan.defaultPlan();
      _takenMedications
        ..clear()
        ..addAll(local.readTakenMedicationsByDate());
    } catch (_) {
      _currentUser = null;
      _medicationPlan = MedicationPlan.defaultPlan();
      _takenMedications.clear();
    }

    _isInitialized = true;
    notifyListeners();

    try {
      await _resyncMedicationNotifications();
    } catch (_) {
      // If resync fails, keep the app usable and surface nothing fatal.
    }
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
    await local.reloadActiveAccountState();
    _medicationPlan =
        local.readMedicationPlan() ?? MedicationPlan.defaultPlan();
    _takenMedications
      ..clear()
      ..addAll(local.readTakenMedicationsByDate());
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

  Future<AuthResult> resetPassword({
    required String email,
    required String phone,
    required String newPassword,
  }) {
    return authService.resetPassword(
      email: email,
      phone: phone,
      newPassword: newPassword,
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
    await local.reloadActiveAccountState();
    _medicationPlan =
        local.readMedicationPlan() ?? MedicationPlan.defaultPlan();
    _takenMedications
      ..clear()
      ..addAll(local.readTakenMedicationsByDate());
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    _currentUser = null;
    final local = await LocalStore.instance();
    await local.clearAuthToken();
    _medicationPlan = MedicationPlan.empty();
    _takenMedications.clear();
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
    await scheduleNotificationsForMedication(medication);
  }

  // Update an existing medication
  Future<void> updateMedication(Medication medication) async {
    Medication? existing;
    for (final candidate in _medicationPlan.medications) {
      if (candidate.id == medication.id) {
        existing = candidate;
        break;
      }
    }

    if (existing != null) {
      await cancelNotificationsForMedication(existing);
    }

    final updated = _medicationPlan.copyWith(
      medications:
          _medicationPlan.medications.map((m) {
            return m.id == medication.id ? medication : m;
          }).toList(),
    );
    await updateMedicationPlan(updated);
    await scheduleNotificationsForMedication(medication);
  }

  // Remove a medication from the plan
  Future<void> removeMedication(String medicationId) async {
    Medication? existing;
    for (final candidate in _medicationPlan.medications) {
      if (candidate.id == medicationId) {
        existing = candidate;
        break;
      }
    }

    if (existing != null) {
      await cancelNotificationsForMedication(existing);
    }

    final updated = _medicationPlan.copyWith(
      medications:
          _medicationPlan.medications
              .where((m) => m.id != medicationId)
              .toList(),
    );
    await updateMedicationPlan(updated);

    final local = await LocalStore.instance();
    _takenMedications.removeWhere((date, takenIds) {
      takenIds.remove(medicationId);
      return takenIds.isEmpty;
    });
    await local.saveTakenMedicationsByDate(_takenMedications);
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

  /// Schedule notifications for a medication (all times of day)
  Future<void> scheduleNotificationsForMedication(Medication medication) async {
    for (final timeOfDay in medication.timesOfDay) {
      final notificationId = '${medication.id}_${timeOfDay.name}'.hashCode;
      await _notificationService.scheduleDailyMedicationReminder(
        id: notificationId.abs(),
        medicationName: medication.name,
        timeOfDay: timeOfDay.defaultTime,
        payload: medication.id,
      );
    }
  }

  /// Cancel notifications for a medication
  Future<void> cancelNotificationsForMedication(Medication medication) async {
    for (final timeOfDay in medication.timesOfDay) {
      final notificationId = '${medication.id}_${timeOfDay.name}'.hashCode;
      await _notificationService.cancelNotification(notificationId.abs());
    }
  }

  Future<void> _resyncMedicationNotifications() async {
    await _notificationService.cancelAllNotifications();
    for (final medication in _medicationPlan.medications) {
      if (medication.isActive) {
        await scheduleNotificationsForMedication(medication);
      }
    }
  }

  /// Show a test notification (for demo)
  Future<void> showTestNotification(String title, String body) async {
    await _notificationService.showNotification(title: title, body: body);
  }

  /// Show the same test payload immediately to compare delivery against scheduling.
  Future<void> showImmediateScheduleComparisonNotification() async {
    await _notificationService.showNotification(
      title: 'Memory2Care test reminder',
      body: 'Immediate delivery comparison notification.',
    );
  }

  /// Schedule a one-off test notification two minutes from now.
  Future<void> scheduleTestNotificationInTwoMinutes() async {
    await _notificationService.scheduleNotificationAfterDuration(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
      title: 'Memory2Care test reminder',
      body: 'This notification was scheduled 2 minutes ago.',
      delay: const Duration(minutes: 2),
    );
  }

  /// Schedule a short test notification after 15 seconds.
  Future<void> scheduleTestNotificationInFifteenSeconds() async {
    await _notificationService.scheduleNotificationAfterDuration(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
      title: 'Memory2Care test reminder',
      body: 'This notification was scheduled 15 seconds ago.',
      delay: const Duration(seconds: 15),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Get pending notifications (for debugging)
  Future<int> getPendingNotificationCount() async {
    final pending = await _notificationService.getPendingNotifications();
    return pending.length;
  }

  /// Get active notifications currently displayed by Android.
  Future<int> getActiveNotificationCount() async {
    final active = await _notificationService.getActiveNotifications();
    return active.length;
  }

  /// Get notification permission/status info (for debugging)
  Future<Map<String, String>> getNotificationPermissions() async {
    return await _notificationService.checkNotificationPermissions();
  }

  List<({DateTime date, int due, int taken})> getAdherenceByDay(
    DateTime start,
    DateTime end, {
    String? medicationId,
  }) {
    final result = <({DateTime date, int due, int taken})>[];
    var current = _normalizeDate(start);
    final normalizedEnd = _normalizeDate(end);

    while (!current.isAfter(normalizedEnd)) {
      final dueMeds = getDueMedicationsForDate(current);
      final filtered =
          medicationId != null
              ? dueMeds.where((m) => m.id == medicationId).toList()
              : dueMeds;
      final takenIds = _takenMedications[current] ?? {};
      final taken = filtered.where((m) => takenIds.contains(m.id)).length;
      result.add((date: current, due: filtered.length, taken: taken));
      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  double getAdherenceRate(
    DateTime start,
    DateTime end, {
    String? medicationId,
  }) {
    final data = getAdherenceByDay(start, end, medicationId: medicationId);
    final relevant = data.where((d) => d.due > 0).toList();
    if (relevant.isEmpty) return 0;
    final totalDue = relevant.fold<int>(0, (s, d) => s + d.due);
    final totalTaken = relevant.fold<int>(0, (s, d) => s + d.taken);
    return totalDue > 0 ? totalTaken / totalDue * 100 : 0;
  }

  int getCurrentStreak({String? medicationId}) {
    var streak = 0;
    var date = _normalizeDate(DateTime.now());

    for (var i = 0; i < 365; i++) {
      final dueMeds = getDueMedicationsForDate(date);
      final filtered =
          medicationId != null
              ? dueMeds.where((m) => m.id == medicationId).toList()
              : dueMeds;

      if (filtered.isEmpty) {
        date = date.subtract(const Duration(days: 1));
        continue;
      }

      final takenIds = _takenMedications[date] ?? {};
      final taken = filtered.where((m) => takenIds.contains(m.id)).length;

      if (taken == filtered.length) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
