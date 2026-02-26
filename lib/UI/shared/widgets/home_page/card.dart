import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app_contants.dart'; // Verifică dacă calea e corectă
import '../../../../Data/models/appointment_model.dart'; // Verifică dacă calea e corectă

class BusySlotCard extends StatelessWidget {
  final Appointment appointment;
  final DateTime slotTime;
  final DateTime selectedDate;

  const BusySlotCard({
    Key? key,
    required this.appointment,
    required this.slotTime,
    required this.selectedDate,
  }) : super(key: key);

  
  Color _getServiceColor(String service) {
    final s = service.toLowerCase();
    
    
    if (s.contains('acupunctură')) {
      return Colors.teal; 
    } else if (s.contains('masaj')) {
      return Colors.orange; 
    } else if (s.contains('infiltrație')) {
      return Colors.deepPurple; 
    } else if (s.contains('reflexoterapie')) {
      return Colors.blueAccent; 
    }
    
    // Dacă adaugi un serviciu nou pe viitor și nu e în listă, va lua culoarea asta implicită:
    return AppColors.bordeaux; 
  }

  @override
  Widget build(BuildContext context) {
    
    final serviceColor = _getServiceColor(appointment.service);

    
    Color statusColor = Colors.blue; 
    if (appointment.status == 'finalizat') statusColor = Colors.green;
    if (appointment.status == 'anulat') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          // AICI ESTE BARA VERTICALĂ COLORATĂ
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: serviceColor, width: 6), // Lățimea de 6px e perfectă
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    
                    Row(
                      children: [
                        Icon(Icons.medical_services_outlined, size: 18, color: serviceColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            appointment.service,
                            style: TextStyle(color: serviceColor, fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (appointment.reason.isNotEmpty) ...[
                      const SizedBox(height: 6),
                     
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.notes, size: 16, color: Colors.grey[700]), // Iconița de notițe
                          const SizedBox(width: 6), // Un mic spațiu între iconiță și text
                          Expanded( // Expanded previne tăierea urâtă a textului dacă e prea lung
                            child: Text(
                              appointment.reason,
                              style: TextStyle(color: Colors.grey[700], fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
              
              const SizedBox(width: 8),

              // 4. STATUS ȘI DURATĂ 
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appointment.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // DURATA
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(
                        '${appointment.duration} min',
                        style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}