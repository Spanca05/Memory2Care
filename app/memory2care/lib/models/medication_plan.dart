import 'package:memory2care/models/medication.dart';
import 'package:memory2care/models/medication_time.dart';

class MedicationPlan {
  MedicationPlan({required this.medications});

  final List<Medication> medications;

  factory MedicationPlan.defaultPlan() {
    return MedicationPlan(
      medications: [
        Medication(
          id: 'default_1',
          name: 'Donepezil',
          dose: '5mg',
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          timesOfDay: [MedicationTime.morning],
          weekdays: {1, 3, 5, 7},
        ),
      ],
    );
  }

  factory MedicationPlan.empty() {
    return MedicationPlan(medications: []);
  }

  bool isDueOn(DateTime date) {
    return medications.any((med) => med.isDueOn(date));
  }

  List<Medication> getDueToday(DateTime date) {
    return medications.where((med) => med.isDueOn(date)).toList();
  }

  MedicationPlan copyWith({List<Medication>? medications}) {
    return MedicationPlan(medications: medications ?? this.medications);
  }

  Map<String, dynamic> toMap() {
    return {'medications': medications.map((m) => m.toMap()).toList()};
  }

  static MedicationPlan fromMap(Map<String, dynamic> map) {
    // Handle legacy single-medication format
    if (map.containsKey('medicationName') && !map.containsKey('medications')) {
      final dose = map['dose'] as String? ?? '';
      final startDate =
          map['startDate'] != null
              ? DateTime.parse(map['startDate'] as String)
              : DateTime.now();
      final weekdays =
          (map['weekdays'] as List<dynamic>?)?.map((e) => e as int).toSet() ??
          {1, 2, 3, 4, 5, 6, 7};

      return MedicationPlan(
        medications: [
          Medication(
            id: 'migrated_${DateTime.now().millisecondsSinceEpoch}',
            name: map['medicationName'] as String,
            dose: dose,
            startDate: startDate,
            timesOfDay: [MedicationTime.morning],
            weekdays: weekdays,
          ),
        ],
      );
    }

    // Handle new multi-medication format
    final medicationsList =
        (map['medications'] as List<dynamic>?)
            ?.map((m) => Medication.fromMap(m as Map<String, dynamic>))
            .toList() ??
        [];

    return medicationsList.isEmpty
        ? MedicationPlan.empty()
        : MedicationPlan(medications: medicationsList);
  }
}
