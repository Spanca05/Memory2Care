import 'package:flutter/material.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/screens/auth/login_screen.dart';
import 'package:memory2care/screens/profile/edit_medication_screen.dart';
import 'package:memory2care/screens/profile/edit_profile_screen.dart';
import 'package:memory2care/widgets/app_scaffold.dart';
import 'package:memory2care/widgets/profile_widgets.dart';
import 'package:memory2care/screens/profile/about_screen.dart';
import 'package:memory2care/screens/profile/help_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final profile = controller.currentUser;

    return AppScaffold(
      title: 'Profile',
      body: ListView(
        children: [
          const SizedBox(height: 18),
          // Profile header card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5D9CEC), Color(0xFF3A6FBC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5D9CEC).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.fullName ?? 'Guest User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profile?.email ?? '',
                        style: const TextStyle(
                          color: Color(0xFFCCE4FF),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(controller: controller),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'Edit profile',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Account section
          ProfileSection(
            items: [
              ProfileItem(
                icon: Icons.person_outline,
                title: 'My Account',
                subtitle: 'Edit personal information',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(controller: controller),
                  ),
                ),
              ),
              ProfileItem(
                icon: Icons.medication_outlined,
                title: 'My Medication',
                subtitle: 'Add and manage medications',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        EditMedicationScreen(controller: controller),
                  ),
                ),
              ),
              ProfileItem(
                icon: Icons.logout,
                title: 'Log out',
                subtitle: 'Sign out of your account',
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: const Text('Confirm log out'),
                          content: const Text(
                            'Are you sure you want to log out?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Log out'),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true) {
                    await controller.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(controller: controller),
                        ),
                        (_) => false,
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Info section
          ProfileSection(
            items: [
              ProfileItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'FAQs and contact',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                ),
              ),
              ProfileItem(
                icon: Icons.favorite_border,
                title: 'About App',
                subtitle: 'Our mission and version info',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
