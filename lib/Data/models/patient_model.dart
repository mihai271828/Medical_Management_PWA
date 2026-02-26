import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id;
  final String name;
  final String phone;
  final String email;

  Patient({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': id,
      'name': name,
      'phone': phone,
      'email': email,
    };
  }

  
  factory Patient.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Patient(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
    );
  }
}