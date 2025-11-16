import 'package:flutter/material.dart';
import 'package:medical_management_pwa/app_contants.dart';

class Statisticalitem extends StatelessWidget{


  final IconData icon;
  final String label;
  final String value;

  const Statisticalitem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.cream, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.cream,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color:  AppColors.cream.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

}




