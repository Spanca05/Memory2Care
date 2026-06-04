import 'package:flutter/material.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/screens/auth/login_screen.dart';
import 'package:memory2care/screens/profile/edit_medication_screen.dart';
import 'package:memory2care/screens/profile/edit_profile_screen.dart';
import 'package:memory2care/utils/snackbar.dart';
import 'package:memory2care/widgets/app_scaffold.dart';
import 'package:memory2care/widgets/profile_widgets.dart';
import 'package:memory2care/screens/profile/about_screen.dart';

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
              ProfileItem(
                icon: Icons.notifications,
                title: 'Schedule in 2 Minutes',
                subtitle: 'Test the real notification scheduler',
                onTap: () async {
                  await controller.scheduleTestNotificationInTwoMinutes();
                  if (context.mounted) {
                    showSnack(
                      context,
                      'Test reminder scheduled for 2 minutes from now',
                    );
                  }
                },
              ),
              ProfileItem(
                icon: Icons.notifications_active,
                title: 'Show Notification Now',
                subtitle:
                    'Compare immediate delivery against scheduled delivery',
                onTap: () async {
                  await controller
                      .showImmediateScheduleComparisonNotification();
                  if (context.mounted) {
                    showSnack(context, 'Immediate notification sent');
                  }
                },
              ),
              ProfileItem(
                icon: Icons.timer,
                title: 'Schedule in 15 Seconds',
                subtitle: 'Quick delivery test for the emulator',
                onTap: () async {
                  await controller.scheduleTestNotificationInFifteenSeconds();
                  if (context.mounted) {
                    showSnack(
                      context,
                      'Test reminder scheduled for 15 seconds from now',
                    );
                  }
                },
              ),
              ProfileItem(
                icon: Icons.info_outline,
                title: 'Check Notification Permissions',
                subtitle: 'Debug: notification and alarm permissions',
                onTap: () async {
                  final perms = await controller.getNotificationPermissions();
                  if (context.mounted) {
                    showSnack(
                      context,
                      'Permissions: notification=${perms['notification']}, exactAlarm=${perms['scheduleExactAlarm']}, platformEnabled=${perms['platformNotificationsEnabled']}',
                    );
                  }
                },
              ),
              ProfileItem(
                icon: Icons.info_outline,
                title: 'Check Pending Notifications',
                subtitle: 'Debug: See how many notifications are scheduled',
                onTap: () async {
                  final count = await controller.getPendingNotificationCount();
                  if (context.mounted) {
                    showSnack(context, 'Pending notifications: $count');
                  }
                },
              ),
              ProfileItem(
                icon: Icons.visibility,
                title: 'Check Active Notifications',
                subtitle: 'Debug: See what is currently displayed',
                onTap: () async {
                  final count = await controller.getActiveNotificationCount();
                  if (context.mounted) {
                    showSnack(context, 'Active notifications: $count');
                  }
                },
              ),
              ProfileItem(
                icon: Icons.logout,
                title: 'Log out',
                subtitle: 'Further secure your account for safety',
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm log out'),
                      content: const Text('Are you sure you want to log out?'),
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
          ProfileSection(
            items: [
              const ProfileItem(icon: Icons.help_outline, title: 'Help & Support'),
              ProfileItem(
                icon: Icons.favorite_border,
                title: 'About App',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
