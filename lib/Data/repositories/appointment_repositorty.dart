import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentRepository {
  final CollectionReference _ref =
      FirebaseFirestore.instance.collection('appointments');


  Future<void> addAppointment(Appointment appointment) {
    final newDocRef = _ref.doc(); 
    
    final appointmentData = appointment.toMap();
    
    appointmentData['id'] = newDocRef.id; 
    
    return newDocRef.set(appointmentData);
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


  Stream<List<Appointment>> getPatientAppointments(String patientId) {
    return _ref
        .where('patientId', isEqualTo: patientId)
        .orderBy('time', descending: true) // Cele mai recente primele
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList();
    });
  }
}