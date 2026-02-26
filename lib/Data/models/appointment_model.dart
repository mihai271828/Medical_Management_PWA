import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
class Appointment {
  final String id;
  final String patientName;
  final String patientId;
  final DateTime time;
  final int duration;
  final String reason;
  final String status;
  final String service;
  final String? subscriptionId;

  Appointment({
    required this.id,
    required this.patientName,
    required this.patientId,
    required this.time,
    required this.duration,
    required this.reason,
    required this.status,
    required this.service,
    this.subscriptionId,
  });

  // Convert Firebase Document to Dart Object
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      patientName: data['patientName'] ?? 'Necunoscut',
      patientId: data['patientId'] ?? '',
      subscriptionId: data['subscriptionId'],
      time: _parseDateSafely(data['time']),
      duration: data['duration'] ?? 30,
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'Programat',
      service: data['service'] ?? 'Nedefinit',
    );
  }

  // Convert Dart Object to Firebase Map (for saving)
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'time': Timestamp.fromDate(time),
      'duration': duration,
      'reason': reason,
      'status': status,
      'subscriptionId': subscriptionId,
      'service': service,
    };
  }

  static DateTime _parseDateSafely(dynamic dateData) {
  if (dateData == null) return DateTime.now();
  
  try {
    if (dateData is Timestamp) {
      return dateData.toDate();
    } else if (dateData is DateTime) {
      return dateData;
    } else if (dateData is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateData);
    } else if (dateData is String) {
      return DateTime.parse(dateData);
    } else {
      // JS Object pe web - accesează proprietățile native
      final dynamic jsObj = dateData;
      try {
        // Firestore Timestamp JS are .seconds și .nanoseconds
        final seconds = jsObj.seconds as int;
        final nanoseconds = (jsObj.nanoseconds as int?) ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + nanoseconds ~/ 1000000,
        );
      } catch (_) {
        return DateTime.parse(dateData.toString());
      }
    }
  } catch (e) {
    debugPrint('Error parsing date: $e | value: $dateData | type: ${dateData.runtimeType}');
    return DateTime.now();
  }
}

}