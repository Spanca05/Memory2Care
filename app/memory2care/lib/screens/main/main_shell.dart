import 'package:flutter/material.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/screens/main/home_screen.dart';
import 'package:memory2care/screens/main/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(controller: widget.controller),
      ProfileScreen(controller: widget.controller),
    ];

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          body: screens[_index],
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: SizedBox(
              height: 66,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _index = 0),
                      icon: Icon(
                        Icons.home_outlined,
                        color:
                            _index == 0
                                ? const Color(0xFF5D9CEC)
                                : Colors.black54,
                      ),
                      label: Text(
                        'Home',
                        style: TextStyle(
                          color:
                              _index == 0
                                  ? const Color(0xFF5D9CEC)
                                  : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _index = 1),
                      icon: Icon(
                        Icons.person_outline,
                        color:
                            _index == 1
                                ? const Color(0xFF5D9CEC)
                                : Colors.black54,
                      ),
                      label: Text(
                        'Profile',
                        style: TextStyle(
                          color:
                              _index == 1
                                  ? const Color(0xFF5D9CEC)
                                  : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
