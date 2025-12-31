import 'package:flutter/material.dart';
import 'UI/shared/widgets/navigation_bar/nav_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'UI/shared/app_theme.dart';
import 'firebase_options.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('ro_RO', null);
  runApp(const MedicalSchedulerApp());
}

class MedicalSchedulerApp extends StatelessWidget {
  const MedicalSchedulerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Semen Vitae Medical',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ro', 'RO'),
      supportedLocales: const [
        Locale('ro', 'RO'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppScaffold(),
    );
  }
}