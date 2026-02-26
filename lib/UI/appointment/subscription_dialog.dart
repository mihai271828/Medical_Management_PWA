import 'package:flutter/material.dart';
import '../../../../app_contants.dart'; 

Future<bool?> showCreateSubscriptionPrompt({
  required BuildContext context,
  required String patientName,
  required String serviceName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Abonament Inexistent', 
        style: TextStyle(color: AppColors.bordeaux),
      ),
      content: Text(
        'Pacientul $patientName nu are un abonament activ pentru $serviceName. Doriți să creați unul acum?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Nu, alege alt serviciu', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true), 
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.bordeaux,
            foregroundColor: AppColors.cream,
          ),
          child: const Text('Creează Abonament'),
        ),
      ],
    ),
  );
}