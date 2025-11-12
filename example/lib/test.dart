import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/steps_page.dart';
import 'providers/sections_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/user_stats_provider.dart';
import 'theme/app_colors.dart';

/// Quick test app to preview the sections page without going through the full flow
/// 
/// To run this instead of main.dart:
/// 1. Temporarily change this file name to main.dart (or rename the original main.dart)
/// 2. Run: flutter run --hot
/// 3. You'll see only the sections page for quick UI testing
/// 
/// OR create a separate entry point by running:
/// flutter run -t lib/test.dart --hot
void main() {
  runApp(const TestSectionsApp());
}

class TestSectionsApp extends StatelessWidget {
  const TestSectionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Providers needed for sections page testing
        ChangeNotifierProvider(create: (_) => SectionsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => UserStatsProvider()),
      ],
      child: MaterialApp(
        title: 'Sections Test',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const TestSectionsWrapper(),
      ),
    );
  }
}

class TestSectionsWrapper extends StatelessWidget {
  const TestSectionsWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionsPage();
  }
}

/// Alternative minimal version - just the sections page with no extras
class MinimalSectionsTest extends StatelessWidget {
  const MinimalSectionsTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SectionsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const SectionsPage(), // Direct sections page, no wrapper
      ),
    );
  }
}

/// Quick switch - uncomment this line and comment the main() above 
/// if you want the absolute minimal version:
// void main() => runApp(const MinimalSectionsTest());
