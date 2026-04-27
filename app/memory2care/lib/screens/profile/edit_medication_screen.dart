import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/models/medication.dart';
import 'package:memory2care/models/medication_time.dart';
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
  late final TextEditingController _startDateCtrl;
  late final TextEditingController _endDateCtrl;
  late Set<int> _weekdays;
  late List<MedicationTime> _timesOfDay;
  Medication? _editingMedication;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _doseCtrl = TextEditingController();
    _startDateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    _endDateCtrl = TextEditingController();
    _weekdays = {1, 2, 3, 4, 5, 6, 7};
    _timesOfDay = [MedicationTime.morning];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
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

  Future<void> _pickEndDate() async {
    if (_endDateCtrl.text.isEmpty) {
      return;
    }
    final initial = DateTime.tryParse(_endDateCtrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDate: initial,
    );
    if (picked != null) {
      _endDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
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

    final medication = Medication(
      id:
          _editingMedication?.id ??
          'med_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      dose: _doseCtrl.text.trim(),
      startDate: DateTime.parse(_startDateCtrl.text),
      endDate:
          _endDateCtrl.text.isNotEmpty
              ? DateTime.parse(_endDateCtrl.text)
              : null,
      timesOfDay: _timesOfDay,
      weekdays: _weekdays,
    );

    if (_editingMedication != null) {
      await widget.controller.updateMedication(medication);
    } else {
      await widget.controller.addMedication(medication);
    }

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
              'Add/Edit Medication',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            const Text(
              'Current Medications',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45),
            ),
            const SizedBox(height: 10),
            MedicationSummaryCard(plan: widget.controller.medicationPlan),
            const SizedBox(height: 20),
            const Text(
              'Add New Medication',
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
            const Text(
              'Times of Day',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  MedicationTime.values
                      .map(
                        (time) => FilterChip(
                          selected: _timesOfDay.contains(time),
                          label: Text(time.displayLabel),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _timesOfDay.add(time);
                              } else {
                                _timesOfDay.remove(time);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _endDateCtrl,
              readOnly: true,
              onTap: _pickEndDate,
              decoration: const InputDecoration(
                hintText: 'End date (optional)',
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF5D9CEC),
                ),
              ),
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
              child: Text(
                _editingMedication != null
                    ? 'Update Medication'
                    : 'Add Medication',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
