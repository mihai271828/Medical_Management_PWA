import 'package:flutter/material.dart';
// IMPORTANT: Make sure these paths match your project's structure!
import '../../../app_contants.dart'; 
import '../../../Data/models/patient_model.dart';
import 'patient_details_screen.dart';

class PatientCard extends StatelessWidget {
  final Patient patient;

  const PatientCard({
    Key? key, 
    required this.patient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        
        // 1. Patient Initial (CircleAvatar)
        leading: CircleAvatar(
          backgroundColor: AppColors.bordeaux.withOpacity(0.1),
          child: Text(
            patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?', 
            style: const TextStyle(color: AppColors.bordeaux, fontWeight: FontWeight.bold),
          ),
        ),
        
        // 2. Patient Name
        title: Text(
          patient.name, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        
        // 3. Patient Phone
        subtitle: patient.phone.isNotEmpty 
            ? Text(patient.phone, style: TextStyle(color: Colors.grey[700]))
            : Text(
                'Fără număr de telefon', 
                style: TextStyle(
                  color: Colors.grey[700], 
                  fontStyle: FontStyle.italic,
                  fontSize: 12),
              ),
              
        trailing: const Icon(Icons.chevron_right, color: Colors.black),
        
        // 4. Navigation to Details Screen
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDetailsScreen(patient: patient),
            ),
          );
        },
      ),
    );
  }
}