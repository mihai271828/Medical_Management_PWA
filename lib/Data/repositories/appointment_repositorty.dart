import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentRepository {
  final CollectionReference _ref =
      FirebaseFirestore.instance.collection('appointments');


  Future<void> addAppointment(Appointment appointment) {
    return _ref.add(appointment.toMap());
  }

  Future<void> updateAppointment(Appointment appointment) {
    return _ref.doc(appointment.id).update(appointment.toMap());
  }
  
  Future<void> deleteAppointment(String id) {
    return _ref.doc(id).delete();
  }
  
  Future<void> updateStatus(String id, String newStatus) {
    return _ref.doc(id).update({'status': newStatus});
  }
}