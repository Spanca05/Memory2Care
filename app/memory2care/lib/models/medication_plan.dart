class MedicationPlan {
  MedicationPlan({
    required this.medicationName,
    required this.dose,
    required this.timesPerWeek,
    required this.startDate,
    required this.weekdays,
  });

  final String medicationName;
  final String dose;
  final int timesPerWeek;
  final DateTime startDate;
  final Set<int> weekdays;

  factory MedicationPlan.defaultPlan() {
    return MedicationPlan(
      medicationName: 'Donepezil',
      dose: '5mg',
      timesPerWeek: 4,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      weekdays: {1, 3, 5, 7},
    );
  }

  bool isDueOn(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    if (normalizedDate.isBefore(normalizedStart)) {
      return false;
    }
    return weekdays.contains(normalizedDate.weekday);
  }

  MedicationPlan copyWith({
    String? medicationName,
    String? dose,
    int? timesPerWeek,
    DateTime? startDate,
    Set<int>? weekdays,
  }) {
    return MedicationPlan(
      medicationName: medicationName ?? this.medicationName,
      dose: dose ?? this.dose,
      timesPerWeek: timesPerWeek ?? this.timesPerWeek,
      startDate: startDate ?? this.startDate,
      weekdays: weekdays ?? this.weekdays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicationName': medicationName,
      'dose': dose,
      'timesPerWeek': timesPerWeek,
      'startDate': startDate.toIso8601String(),
      'weekdays': weekdays.toList(),
    };
  }

  static MedicationPlan fromMap(Map<String, dynamic> map) {
    return MedicationPlan(
      medicationName: map['medicationName'] as String,
      dose: map['dose'] as String,
      timesPerWeek: map['timesPerWeek'] as int,
      startDate: DateTime.parse(map['startDate'] as String),
      weekdays: (map['weekdays'] as List<dynamic>).map((e) => e as int).toSet(),
    );
  }
}
