import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
class Subscription {
  final String id;
  final String patientId; 
  final String patientName; 
  final String service; 
  final int totalSessions; 
  final int usedSessions; 
  final String status; 
  final DateTime createdAt;
  final DateTime? completedAt; // NOU: Data în care a fost finalizat (poate fi null inițial)

  final double totalPrice;
  final double amountPaid;

  Subscription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.service,
    required this.totalSessions,
    required this.usedSessions,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.totalPrice = 1500.0, 
    this.amountPaid = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'service': service,
      'totalSessions': totalSessions,
      'usedSessions': usedSessions,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      
      'completedAt':  completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'totalPrice': totalPrice,
      'amountPaid': amountPaid,
    };
  }

  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Subscription(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      service: data['service'] ?? '',
      totalSessions: data['totalSessions'] ?? 10,
      usedSessions: data['usedSessions'] ?? 0,
      status: data['status'] ?? 'activ',
      // === OFFLINE SAFE PARSING ===
      createdAt: _parseDateSafely(data['createdAt']),
      completedAt: data['completedAt'] != null ? _parseDateSafely(data['completedAt']) : null,
      totalPrice: (data['totalPrice'] ?? 1500.0).toDouble(),
      amountPaid: (data['amountPaid'] ?? 0.0).toDouble(),
    );
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
      // JS Object pe web
      try {
        final seconds = (dateData as dynamic).seconds as int;
        final nanoseconds = ((dateData as dynamic).nanoseconds as int?) ?? 0;
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