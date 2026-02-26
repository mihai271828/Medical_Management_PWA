import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';

class PatientRepository {
  final CollectionReference _patientsRef = FirebaseFirestore.instance.collection('patients');

  Future<void> addPatient(Patient patient) {
    final docRef = _patientsRef.doc(patient.id);
    final data = patient.toMap();
    data['id'] = docRef.id;
    
    return docRef.set(data);
  }

  Future<void> updatePatient(Patient patient) async {
    await _patientsRef.doc(patient.id).update(patient.toMap());
  }

  Future<void> deletePatient(String id) async {
    await _patientsRef.doc(id).delete();
  }

  Future<List<Patient>> getAllPatients() async {
    final snapshot = await _patientsRef.get();
    return snapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList();
  }
  
  Stream<List<Patient>> getPatientsStream() {
    return _patientsRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList();
    });
  }
}