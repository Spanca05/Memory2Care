enum MedicationTime {
  morning('06:00', 'Morning'),
  afternoon('12:00', 'Afternoon'),
  evening('18:00', 'Evening');

  const MedicationTime(this.defaultTime, this.displayLabel);

  final String defaultTime;
  final String displayLabel;

  static MedicationTime? fromString(String value) {
    return MedicationTime.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MedicationTime.morning,
    );
  }
}
