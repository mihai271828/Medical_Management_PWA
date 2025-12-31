import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientName;
  final DateTime time;
  final int duration;
  final String reason;
  final String status;

  Appointment({
    required this.id,
    required this.patientName,
    required this.time,
    required this.duration,
    required this.reason,
    required this.status,
  });

  // Convert Firebase Document to Dart Object
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      patientName: data['patientName'] ?? '',
      // Firebase stores dates as 'Timestamp', we convert to DateTime
      time: (data['time'] as Timestamp).toDate(),
      duration: data['duration'] ?? 30,
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'scheduled',
    );
  }

  // Convert Dart Object to Firebase Map (for saving)
  Map<String, dynamic> toMap() {
    return {
      'patientName': patientName,
      'time': Timestamp.fromDate(time),
      'duration': duration,
      'reason': reason,
      'status': status,
    };
  }
}