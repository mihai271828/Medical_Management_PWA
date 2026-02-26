import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../Data/models/appointment_model.dart';
import '../../Data/models/subscription_model.dart';

class AppointmentSyncService {
  
  static Future<void> checkAndAutoUpdatePastAppointments(List<Appointment> appointments) async {
    final now = DateTime.now();

    for (var app in appointments) {
      final endTime = app.time.add(Duration(minutes: app.duration));

      if (app.status == 'programat' && now.isAfter(endTime)) {
        
         await FirebaseFirestore.instance.collection('appointments').doc(app.id).update({
          'status': 'finalizat'
        });

        if (app.subscriptionId != null && app.subscriptionId!.isNotEmpty) {
          try {
            final subDoc = await FirebaseFirestore.instance.collection('subscriptions').doc(app.subscriptionId).get();
            
            if (subDoc.exists) {
              final sub = Subscription.fromFirestore(subDoc);
              int newUsed = sub.usedSessions + 1;
              
              Map<String, dynamic> subUpdates = {
                'usedSessions': newUsed
              };

              
              if (newUsed >= sub.totalSessions && sub.status != 'finalizat') {
                subUpdates['status'] = 'finalizat';
                subUpdates['completedAt'] = Timestamp.fromDate(endTime); 
              }

              await FirebaseFirestore.instance.collection('subscriptions').doc(sub.id).update(subUpdates);
            }
          } catch (e) {
            debugPrint('Eroare la auto-update abonament: $e');
          }
        }
      }
    }
  }
}