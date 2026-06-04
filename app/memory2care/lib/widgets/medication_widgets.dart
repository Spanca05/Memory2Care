import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/models/medication.dart';
import 'package:memory2care/models/medication_plan.dart';

class MedicationSummaryCard extends StatelessWidget {
  const MedicationSummaryCard({super.key, required this.plan});

  final MedicationPlan plan;

  @override
  Widget build(BuildContext context) {
    if (plan.medications.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'No medications added yet',
            style: TextStyle(color: Colors.black45),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Medications (${plan.medications.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...plan.medications.map((med) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dose: ${med.dose}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    'Times: ${med.timesOfDay.map((t) => t.displayLabel).join(", ")}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    'Start: ${DateFormat('dd MMM yyyy').format(med.startDate)}${med.endDate != null ? " - ${DateFormat('dd MMM yyyy').format(med.endDate!)}" : ""}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if (!med.isActive)
                    const Text(
                      '(Inactive)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class CalendarCard extends StatelessWidget {
  const CalendarCard({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final month = controller.focusedMonth;
    final firstDay = DateTime(month.year, month.month, 1);
    final firstWeekdaySlot = firstDay.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    final cells = <DateTime?>[];
    for (var i = 0; i < firstWeekdaySlot; i++) {
      cells.add(null);
    }
    for (var day = 1; day <= daysInMonth; day++) {
      cells.add(DateTime(month.year, month.month, day));
    }

    final dayLabels = const ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed:
                    () => controller.setFocusedMonth(
                      DateTime(month.year, month.month - 1),
                    ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM yyyy').format(month),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    () => controller.setFocusedMonth(
                      DateTime(month.year, month.month + 1),
                    ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children:
                dayLabels
                    .map(
                      (label) => Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black45,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: cells.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final date = cells[index];
              if (date == null) {
                return const SizedBox.shrink();
              }

              final due = controller.isDueDate(date);
              final dueMeds = controller.getDueMedicationsForDate(date);
              final takenCount = controller.getTakenCountForDate(date);
              final today = DateUtils.isSameDay(date, DateTime.now());

              Color? background;
              Color textColor = Colors.black54;

              if (due) {
                if (takenCount == dueMeds.length) {
                  // All medications taken
                  background = const Color(0xFF98E8A5);
                  textColor = Colors.white;
                } else if (takenCount > 0) {
                  // Some medications taken
                  background = const Color(0xFFFFF9C4);
                  textColor = Colors.black87;
                } else {
                  // Due but none taken
                  background = const Color(0xFFE8F3FF);
                  textColor = const Color(0xFF3B75C4);
                }
              }

              if (today) {
                background = const Color(0xFFFF5A3D);
                textColor = Colors.white;
              }

              return GestureDetector(
                onTap:
                    due
                        ? () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => MedicationDialog(
                                  date: date,
                                  dueMeds: dueMeds,
                                  controller: controller,
                                ),
                          );
                        }
                        : null,
                child: Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: background,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tip: Tap colored days to mark medications as taken.',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }
}

class MedicationDialog extends StatelessWidget {
  const MedicationDialog({
    super.key,
    required this.date,
    required this.dueMeds,
    required this.controller,
  });

  final DateTime date;
  final List<Medication> dueMeds;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(DateFormat('dd MMM yyyy').format(date)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            dueMeds
                .map(
                  (med) => CheckboxListTile(
                    title: Text(med.name),
                    subtitle: Text(
                      '${med.dose} - ${med.timesOfDay.map((t) => t.displayLabel).join(", ")}',
                    ),
                    value: controller.isMedicationTaken(med.id, date),
                    onChanged:
                        (_) => controller.toggleMedicationTaken(med.id, date),
                  ),
                )
                .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
