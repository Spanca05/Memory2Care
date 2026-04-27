import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/models/medication_plan.dart';
import 'package:memory2care/utils/snackbar.dart';
import 'package:memory2care/utils/validators.dart';
import 'package:memory2care/widgets/app_scaffold.dart';
import 'package:memory2care/widgets/medication_widgets.dart';

class EditMedicationScreen extends StatefulWidget {
  const EditMedicationScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _doseCtrl;
  late final TextEditingController _timesCtrl;
  late final TextEditingController _startDateCtrl;
  late Set<int> _weekdays;

  @override
  void initState() {
    super.initState();
    final plan = widget.controller.medicationPlan;
    _nameCtrl = TextEditingController(text: plan.medicationName);
    _doseCtrl = TextEditingController(text: plan.dose);
    _timesCtrl = TextEditingController(text: plan.timesPerWeek.toString());
    _startDateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(plan.startDate),
    );
    _weekdays = {...plan.weekdays};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _timesCtrl.dispose();
    _startDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final initial = DateTime.tryParse(_startDateCtrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDate: initial,
    );
    if (picked != null) {
      _startDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_weekdays.isEmpty) {
      showSnack(context, 'Select at least one weekday');
      return;
    }

    final plan = MedicationPlan(
      medicationName: _nameCtrl.text.trim(),
      dose: _doseCtrl.text.trim(),
      timesPerWeek: int.parse(_timesCtrl.text.trim()),
      startDate: DateTime.parse(_startDateCtrl.text),
      weekdays: _weekdays,
    );

    await widget.controller.updateMedicationPlan(plan);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Edit the Medication',
      showBack: true,
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 6),
            const Text(
              'Edit Medication',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            const Text(
              'your current medication',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45),
            ),
            const SizedBox(height: 10),
            MedicationSummaryCard(plan: widget.controller.medicationPlan),
            const SizedBox(height: 20),
            const Text(
              'add new medication',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'Medication name'),
              validator: (value) => requiredField(value, 'Medication name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _doseCtrl,
              decoration: const InputDecoration(
                hintText: 'What is the dose of the medication?',
              ),
              validator: (value) => requiredField(value, 'Dose'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _timesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'How many times a week do you need to take it?',
              ),
              validator: (value) {
                final raw = value?.trim() ?? '';
                if (raw.isEmpty) {
                  return 'Times per week is required';
                }
                final n = int.tryParse(raw);
                if (n == null || n < 1 || n > 7) {
                  return 'Enter a number between 1 and 7';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _startDateCtrl,
              readOnly: true,
              onTap: _pickStartDate,
              decoration: const InputDecoration(
                hintText: 'When are you starting the medication?',
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF5D9CEC),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Start date is required';
                }
                if (DateTime.tryParse(value) == null) {
                  return 'Invalid date format';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'Medication weekdays',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final day = index + 1;
                final label = DateFormat('EEE').format(DateTime(2024, 1, day));
                final selected = _weekdays.contains(day);
                return FilterChip(
                  selected: selected,
                  label: Text(label),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _weekdays.add(day);
                      } else {
                        _weekdays.remove(day);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Update Medication'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
