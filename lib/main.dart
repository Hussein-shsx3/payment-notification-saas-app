import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'src/core/auth/auth_provider.dart';
import 'src/core/background/workmanager_service.dart';
import 'src/core/locale/locale_controller.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/shell/main_shell.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => LocaleController()..load(),
        ),
      ],
      child: Consumer2<AuthProvider, LocaleController>(
        builder: (context, auth, localeCtrl, _) {
          final baseDark = ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF020617),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF06B6D4),
              secondary: Color(0xFF0F172A),
              surface: Color(0xFF0F172A),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0B1220),
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF1E293B)),
              ),
            ),
            textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
          );

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Payment Notify',
            locale: localeCtrl.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: baseDark,
            builder: (context, child) {
              final code = Localizations.localeOf(context).languageCode;
              final theme = Theme.of(context);
              final textTheme = code == 'ar'
                  ? GoogleFonts.notoSansArabicTextTheme(theme.textTheme)
                  : GoogleFonts.notoSansTextTheme(theme.textTheme);
              return Theme(
                data: theme.copyWith(textTheme: textTheme),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: auth.isLoading
                ? const _LoadingScreen()
                : (auth.isAuthenticated
                    ? const MainShell()
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
        child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
      ),
    );
  }
}
