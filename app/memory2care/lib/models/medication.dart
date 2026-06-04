import 'package:memory2care/models/medication_time.dart';

class Medication {
  Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.startDate,
    this.endDate,
    required this.timesOfDay,
    required this.weekdays,
    this.isActive = true,
    this.notes,
  });

  final String id;
  final String name;
  final String dose;
  final DateTime startDate;
  final DateTime? endDate;
  final List<MedicationTime> timesOfDay;
  final Set<int> weekdays;
  final bool isActive;
  final String? notes;

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

    if (endDate != null) {
      final normalizedEnd = DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
      );
      if (normalizedDate.isAfter(normalizedEnd)) {
        return false;
      }
    }

    return isActive && weekdays.contains(normalizedDate.weekday);
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dose,
    DateTime? startDate,
    DateTime? endDate,
    List<MedicationTime>? timesOfDay,
    Set<int>? weekdays,
    bool? isActive,
    String? notes,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timesOfDay: timesOfDay ?? this.timesOfDay,
      weekdays: weekdays ?? this.weekdays,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dose': dose,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'timesOfDay': timesOfDay.map((e) => e.name).toList(),
      'weekdays': weekdays.toList(),
      'isActive': isActive,
      'notes': notes,
    };
  }

  static Medication fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as String,
      name: map['name'] as String,
      dose: map['dose'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate:
          map['endDate'] != null
              ? DateTime.parse(map['endDate'] as String)
              : null,
      timesOfDay:
          (map['timesOfDay'] as List<dynamic>?)
              ?.map(
                (e) =>
                    MedicationTime.fromString(e as String) ??
                    MedicationTime.morning,
              )
              .toList() ??
          [MedicationTime.morning],
      weekdays:
          (map['weekdays'] as List<dynamic>?)?.map((e) => e as int).toSet() ??
          {},
      isActive: map['isActive'] as bool? ?? true,
      notes: map['notes'] as String?,
    );
  }
}
