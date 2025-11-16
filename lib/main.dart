import 'package:flutter/material.dart';
import 'UI/shared/widgets/navigation_bar/nav_bar.dart';
import 'app.dart';
import 'UI/shared/app_theme.dart';
void main()  {
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
      home: const AppScaffold(),
    );
  }
}