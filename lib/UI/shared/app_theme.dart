import 'package:flutter/material.dart';
import 'package:medical_management_pwa/App_contants.dart'; 

class AppTheme {
  
  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.bordeaux,
          surface: AppColors.cream,
        ),
        useMaterial3: true,
      );

  
  static ThemeData get dark => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.bordeaux,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
}
