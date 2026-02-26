import 'package:flutter/material.dart';
import '../../app_contants.dart';
import '../../Data/models/patient_model.dart';
import '../../Data/repositories/patient_repository.dart';
import 'patient_details_screen.dart';
import 'patient_card.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({Key? key}) : super(key: key);

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final PatientRepository _patientRepo = PatientRepository();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,

      body: Column(
        children: [
          // BARA DE CĂUTARE
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            color: AppColors.bordeaux,
            child: TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Caută pacient...',
                prefixIcon: const Icon(Icons.search, color: AppColors.bordeaux),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // LISTA DE PACIENȚI
          Expanded(
            child: StreamBuilder<List<Patient>>(
              stream: _patientRepo.getPatientsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.bordeaux),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Eroare: ${snapshot.error}'));
                }

                final allPatients = snapshot.data ?? [];

                // Filtrăm pacienții în funcție de ce am scris în bara de căutare
                final filteredPatients = allPatients.where((p) {
                  return p.name.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredPatients.isEmpty) {
                  return _buildEmptyState('Nu a fost găsit niciun pacient.');
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredPatients.length,
                  itemBuilder: (context, index) {
                    final patient = filteredPatients[index];

                    return Dismissible(
                      key: Key(patient.id),

                      direction: DismissDirection.endToStart,

                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bordeaux,
                          borderRadius: BorderRadius.circular(
                            16,
                          ), 
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Confirmare ștergere"),
                              content: Text(
                                "Sigur dorești să ștergi pacientul ${patient.name}?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("Anulare"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text(
                                    "Șterge",
                                    style: TextStyle(color: AppColors.bordeaux),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },

                      
                      onDismissed: (direction) {
                        
                        _patientRepo.deletePatient(patient.id);

                       
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${patient.name} a fost șters.',
                              style: const TextStyle(color: Colors.white),
                            ),

                            backgroundColor: Colors.grey,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },

                      // Cardul propriu-zis
                      child: PatientCard(patient: patient),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
