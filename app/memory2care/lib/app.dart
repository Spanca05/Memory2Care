import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/screens/auth/login_screen.dart';
import 'package:memory2care/screens/main/main_shell.dart';
import 'package:memory2care/services/auth_service.dart';
import 'package:memory2care/widgets/splash_screen.dart';

class Memory2CareBootstrap extends StatefulWidget {
  const Memory2CareBootstrap({super.key});

  @override
  State<Memory2CareBootstrap> createState() => _Memory2CareBootstrapState();
}

class _Memory2CareBootstrapState extends State<Memory2CareBootstrap> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController(
      authService: AuthService(
        baseUrl: const String.fromEnvironment('API_BASE_URL'),
      ),
    );
    _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Memory2CareApp(controller: _controller);
      },
    );
  }
}

class Memory2CareApp extends StatelessWidget {
  const Memory2CareApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF5D9CEC);
    const scaffoldGray = Color(0xFFF4F5F7);

    return MaterialApp(
      title: 'Memory2Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: scaffoldGray,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
        textTheme: GoogleFonts.poppinsTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          errorMaxLines: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home:
          !controller.isInitialized
              ? const SplashScreen()
              : controller.currentUser == null
              ? LoginScreen(controller: controller)
              : MainShell(controller: controller),
    );
  }
}
