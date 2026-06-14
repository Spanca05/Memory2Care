import 'package:flutter/material.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/screens/ar/ar_scan_screen.dart';
import 'package:memory2care/screens/main/home_screen.dart';
import 'package:memory2care/screens/main/profile_screen.dart';
import 'package:memory2care/screens/main/stats_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _blue = Color(0xFF5D9CEC);
  static const _inactive = Colors.black45;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(controller: widget.controller),
      StatsScreen(controller: widget.controller),
      ProfileScreen(controller: widget.controller),
    ];

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          body: screens[_index],
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 60,
                child: Row(
                  children: [
                    Expanded(
                      child: _navItem(
                        Icons.home_outlined,
                        Icons.home,
                        'Home',
                        0,
                      ),
                    ),
                    Expanded(
                      child: _navItem(
                        Icons.bar_chart,
                        Icons.bar_chart,
                        'Stats',
                        1,
                      ),
                    ),
                    Expanded(child: _qrItem(context)),
                    Expanded(
                      child: _navItem(
                        Icons.person_outline,
                        Icons.person,
                        'Profile',
                        2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _navItem(IconData iconOff, IconData iconOn, String label, int idx) {
    final active = _index == idx;
    return TextButton(
      onPressed: () => setState(() => _index = idx),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: active ? _blue : _inactive,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            active ? iconOn : iconOff,
            size: 22,
            color: active ? _blue : _inactive,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? _blue : _inactive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrItem(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ArScanScreen(controller: widget.controller),
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: _blue,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code_scanner, size: 20, color: Colors.white),
          ),
          const SizedBox(height: 2),
          const Text(
            'Scan',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _blue,
            ),
          ),
        ],
      ),
    );
  }
}
