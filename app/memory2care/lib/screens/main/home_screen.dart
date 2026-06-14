import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/models/medication.dart';
import 'package:memory2care/widgets/app_scaffold.dart';
import 'package:memory2care/widgets/medication_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Memory2Care',
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _GreetingCard(controller: controller),
          const SizedBox(height: 16),
          _TodayCard(controller: controller),
          const SizedBox(height: 16),
          CalendarCard(controller: controller),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting =
        hour < 12
            ? 'Good morning'
            : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    final firstName =
        controller.currentUser?.fullName.split(' ').first ?? 'there';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5D9CEC), Color(0xFF3A6FBC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $firstName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM').format(now),
                  style: const TextStyle(
                    color: Color(0xFFCCE4FF),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final dueMeds = controller.getDueMedicationsForDate(today);
    final takenCount = controller.getTakenCountForDate(today);

    if (dueMeds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All clear!',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  'No medications due today.',
                  style: TextStyle(color: Colors.black45, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final allTaken = takenCount == dueMeds.length;
    final progress = takenCount / dueMeds.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's medications",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      allTaken
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFE8F3FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$takenCount / ${dueMeds.length}',
                  style: TextStyle(
                    color:
                        allTaken
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF5D9CEC),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation(
                allTaken ? const Color(0xFF4CAF50) : const Color(0xFF5D9CEC),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...dueMeds.map(
            (med) => _MedRow(
              medication: med,
              taken: controller.isMedicationTaken(med.id, today),
              onToggle: () => controller.toggleMedicationTaken(med.id, today),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedRow extends StatelessWidget {
  const _MedRow({
    required this.medication,
    required this.taken,
    required this.onToggle,
  });

  final Medication medication;
  final bool taken;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                    taken
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF0F4FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                taken ? Icons.check : Icons.medication_outlined,
                color:
                    taken ? const Color(0xFF4CAF50) : const Color(0xFF5D9CEC),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: taken ? Colors.black38 : Colors.black87,
                      decoration: taken ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    '${medication.dose} · ${medication.timesOfDay.map((t) => t.displayLabel).join(", ")}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              taken
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked_outlined,
              color: taken ? const Color(0xFF4CAF50) : Colors.black26,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
