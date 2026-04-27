import 'package:flutter/material.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/widgets/app_scaffold.dart';
import 'package:memory2care/widgets/medication_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final plan = controller.medicationPlan;
    return AppScaffold(
      title: 'Memory2Care',
      body: ListView(
        children: [
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'my medication',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 12),
          MedicationSummaryCard(plan: plan),
          const SizedBox(height: 22),
          CalendarCard(controller: controller),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
