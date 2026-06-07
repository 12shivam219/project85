import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/database/hive_boxes.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/screens/main_shell.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize local Hive Database
  await HiveBoxes.init();

  // 2. Initialize timezone database
  tz.initializeTimeZones();

  runApp(
    const ProviderScope(
      child: Project85App(),
    ),
  );
}

class Project85App extends ConsumerWidget {
  const Project85App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Project 85',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainShell(),
    );
  }
}
