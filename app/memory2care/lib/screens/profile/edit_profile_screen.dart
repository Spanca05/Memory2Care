import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/models/user_profile.dart';
import 'package:memory2care/utils/validators.dart';
import 'package:memory2care/widgets/app_scaffold.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _birthDateCtrl;
  String _gender = 'Prefer not to say';

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.currentUser;
    _nameCtrl = TextEditingController(text: profile?.fullName ?? '');
    _emailCtrl = TextEditingController(text: profile?.email ?? '');
    _phoneCtrl = TextEditingController(text: profile?.phone ?? '');
    _birthDateCtrl = TextEditingController(
      text:
          profile == null
              ? ''
              : DateFormat('yyyy-MM-dd').format(profile.birthDate),
    );
    _gender = profile?.gender ?? 'Prefer not to say';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial =
        DateTime.tryParse(_birthDateCtrl.text) ?? DateTime(now.year - 25, 1, 1);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1920, 1, 1),
      lastDate: now,
      initialDate: initial,
    );
    if (picked != null) {
      _birthDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final birthDate = DateTime.parse(_birthDateCtrl.text);
    final base = widget.controller.currentUser;
    final updated = (base ??
            UserProfile(
              fullName: '',
              email: '',
              phone: '',
              gender: 'Prefer not to say',
              birthDate: DateTime(2000, 1, 1),
            ))
        .copyWith(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          gender: _gender,
          birthDate: birthDate,
        );

    await widget.controller.updateProfile(updated);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Edit Profile',
      showBack: true,
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 6),
            const Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 44,
              backgroundColor: Color(0xFFDDECFF),
              child: Icon(Icons.person, color: Color(0xFF5D9CEC), size: 48),
            ),
            const SizedBox(height: 12),
            Text(
              widget.controller.currentUser?.fullName ?? 'User',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.controller.currentUser?.email ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'Full name'),
              validator: (value) => requiredField(value, 'Full name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(hintText: 'Email'),
              validator: validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(hintText: 'Phone number'),
              validator: validatePhone,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(),
              items: const [
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
                DropdownMenuItem(
                  value: 'Prefer not to say',
                  child: Text('Prefer not to say'),
                ),
              ],
              onChanged: (value) => setState(() => _gender = value ?? _gender),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _birthDateCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                hintText: 'Date of birth',
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF5D9CEC),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Date of birth is required';
                }
                if (DateTime.tryParse(value) == null) {
                  return 'Invalid date format';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Update Profile'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
