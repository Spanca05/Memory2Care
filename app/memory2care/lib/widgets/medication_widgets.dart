import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/models/medication_plan.dart';

class MedicationSummaryCard extends StatelessWidget {
  const MedicationSummaryCard({super.key, required this.plan});

  final MedicationPlan plan;

  @override
  Widget build(BuildContext context) {
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
            plan.medicationName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('Dose: ${plan.dose}'),
          Text('Times per week: ${plan.timesPerWeek}'),
          Text(
            'Start date: ${DateFormat('dd MMM yyyy').format(plan.startDate)}',
          ),
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
              final taken = controller.isTaken(date);
              final today = DateUtils.isSameDay(date, DateTime.now());

              Color? background;
              Color textColor = Colors.black54;
              if (taken) {
                background = const Color(0xFF98E8A5);
                textColor = Colors.white;
              } else if (due) {
                background = const Color(0xFFE8F3FF);
                textColor = const Color(0xFF3B75C4);
              }
              if (today) {
                background = const Color(0xFFFF5A3D);
                textColor = Colors.white;
              }

              return GestureDetector(
                onTap: due ? () => controller.toggleTaken(date) : null,
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
              'Tip: Tap light-blue days to mark medication as taken.',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }
}
