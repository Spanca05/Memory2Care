import 'package:flutter/material.dart';
import 'package:memory2care/widgets/app_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'About Us',
      showBack: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              'Memory2Care',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            Text(
              'Breast cancer is one of the most prevalent diseases worldwide, and while survival rates have improved significantly, the journey does not end with treatment. Many survivors face cognitive side effects from chemotherapy. One of the most impactful consequences is the impairment of prospective memory: the ability to remember to perform future actions, such as taking medication or attending a medical appointment. These everyday failures can compromise treatment adherence and the daily autonomy of patients.\n\n'
              'Existing solutions, such as standard calendar apps, fall short because they lack awareness of the user\'s context and environment, offering reminders that are easy to miss or ignore.\n\n'
              'With Memory2Care we want to change that. Our mission is to develop an innovative digital health tool that uses Augmented Reality to deliver intelligent, context-aware reminders. Imagine a visual cue appearing on your screen the moment you walk into the kitchen, or when your camera detects your medication package. That is the power of contextual memory support.\n\n'
              'Memory2Care is more than an app. It\'s coding for social impact — a commitment to improving the quality of life of cancer survivors through thoughtful, purposeful innovation.',
            ),
          ],
        ),
      ),
    );
  }
}
