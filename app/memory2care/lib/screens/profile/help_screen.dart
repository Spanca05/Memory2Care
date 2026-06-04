import 'package:flutter/material.dart';
import 'package:memory2care/widgets/app_scaffold.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Help & Support',
      showBack: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              'Help & Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            Text(
              'Welcome to the Memory2Care support page. We are here to help you get the most out of your experience and ensure the app works smoothly for your daily needs.',
            ),
            SizedBox(height: 16),
            Text(
              'Getting Started',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('If this is your first time using Memory2Care, here are a few things to keep in mind:'),
            SizedBox(height: 12),
            Text('• Allow camera access when prompted — this is essential for the Augmented Reality features to detect your environment and medication packages.'),
            SizedBox(height: 12),
            Text('• Enable location/context permissions so the app can deliver reminders at the right place and time.'),
            SizedBox(height: 12),
            Text('• Set up your reminders by navigating to the Reminders section and adding your medications, appointments, or daily tasks.'),
            SizedBox(height: 16),
            Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              '• Can I use the app without Augmented Reality?Yes. While AR contextual cues are our core feature, standard reminders and calendar-based alerts are also available for moments when AR is not practical.',
            ),
            SizedBox(height: 12),
            Text(
              '• Is my data safe? Yes. Memory2Care is designed with patient privacy in mind. Your personal data and health information are stored securely and never shared with third parties without your consent.',
            ),
            SizedBox(height: 12),
            Text(
              '• Why is the AR reminder not appearing? Make sure your camera permissions are enabled and that you are in adequate lighting conditions. AR cues work best when the environment is well lit and the camera has a clear view.',
            ),
            SizedBox(height: 12),
            Text(
              '• The app is not sending me notifications. What should I do?Check that notifications are enabled for Memory2Care in your device settings. Also ensure the app is not running in battery saver mode, which can delay or block notifications.',
            ),
            SizedBox(height: 16),
            Text(
              'Contact Us',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'If you couldn\'t find the answer you were looking for, our team is happy to help. 📧 Email: support@memory2care.com.',
            ),
          ],
        ),
      ),
    );
  }
}
