import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'src/core/auth/auth_provider.dart';
import 'src/core/background/workmanager_service.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/dashboard/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await WorkmanagerService.initialize();
  await WorkmanagerService.registerQueueFlushTask();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Payment Notify',
            theme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF020617),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF06B6D4),
                secondary: Color(0xFF0F172A),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF0B1220),
                elevation: 0,
              ),
            ),
            home: auth.isLoading
                ? const _LoadingScreen()
                : (auth.isAuthenticated
                      ? const DashboardScreen()
                      : const LoginScreen()),
          );
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
