import 'package:flutter/material.dart';
import 'UI/shared/widgets/navigation_bar/nav_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';     
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'UI/shared/app_theme.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;
import 'package:flutter/foundation.dart';

//Flavour command : flutter run --dart-define=FLAVOR=dev --chrome
// commands for prod to deploy and host: 
// flutter clean
// flutter pub get


// flutter build web --release --dart-define=FLAVOR=prod

// firebase projects:list
// firebase use <ID-PROIECT-PROD>


// firebase deploy --only hosting
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  final isProd = flavor == 'prod';
  
  await Firebase.initializeApp(
    options: isProd 
        ? prod.DefaultFirebaseOptions.currentPlatform
        : dev.DefaultFirebaseOptions.currentPlatform,
  );
  
 

  if (!kIsWeb) {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 41943040,
  );
  }  
  if (!isProd) {
    try {
      
      // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      debugPrint('Connected to local Firebase Emulators');
    } catch (e) {
      debugPrint('Failed to connect to emulator: $e');
    }
  }

  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    debugPrint('Autentificat anonim cu succes! UID: ${userCredential.user?.uid}');
  } on FirebaseAuthException catch (e) {
    debugPrint('Eroare Firebase Auth: ${e.code} - ${e.message}');
  } catch (e) {
    debugPrint('Eroare necunoscută la autentificare: $e');
  }

  await initializeDateFormatting('ro_RO', null);
  
  runApp(MedicalSchedulerApp(isProd: isProd));
}

class MedicalSchedulerApp extends StatelessWidget {

  final bool isProd;
  const MedicalSchedulerApp({Key? key, required this.isProd}) : super(key: key);
  

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