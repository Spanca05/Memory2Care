import 'package:flutter/material.dart';
import 'package:memory2care/app.dart';
import 'package:memory2care/platform/database_factory_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDesktopDatabaseFactory();
  runApp(const Memory2CareBootstrap());
}
