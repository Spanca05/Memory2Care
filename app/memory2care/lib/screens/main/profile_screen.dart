import 'package:flutter/material.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/screens/auth/login_screen.dart';
import 'package:memory2care/screens/profile/edit_medication_screen.dart';
import 'package:memory2care/screens/profile/edit_profile_screen.dart';
import 'package:memory2care/widgets/app_scaffold.dart';
import 'package:memory2care/widgets/profile_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final profile = controller.currentUser;

    return AppScaffold(
      title: 'Memory2Care',
      body: ListView(
        children: [
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF5D9CEC),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFFDDECFF),
                  child: Icon(Icons.person, color: Color(0xFF5D9CEC), size: 34),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.fullName ?? 'Guest User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile?.username ?? '@guest',
                        style: const TextStyle(color: Color(0xFFCDE2FF)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => EditProfileScreen(controller: controller),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ProfileSection(
            items: [
              ProfileItem(
                icon: Icons.person_outline,
                title: 'My Account',
                subtitle: 'Make changes to your account',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(controller: controller),
                    ),
                  );
                },
              ),
              ProfileItem(
                icon: Icons.medication_outlined,
                title: 'My Medication',
                subtitle: 'Manage your medication',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => EditMedicationScreen(controller: controller),
                    ),
                  );
                },
              ),
              const ProfileItem(
                icon: Icons.shield_outlined,
                title: 'Face ID / Touch ID',
                subtitle: 'Manage your device security',
                trailing: FakeToggle(),
              ),
              ProfileItem(
                icon: Icons.logout,
                title: 'Log out',
                subtitle: 'Further secure your account for safety',
                onTap: () async {
                  await controller.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(controller: controller),
                      ),
                      (_) => false,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const ProfileSection(
            items: [
              ProfileItem(icon: Icons.help_outline, title: 'Help & Support'),
              ProfileItem(icon: Icons.favorite_border, title: 'About App'),
            ],
          ),
        ],
      ),
    );
  }
}
