import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app_contants.dart';
import '../../Data/models/patient_model.dart';
import '../../Data/models/appointment_model.dart';
import '../../Data/repositories/appointment_repositorty.dart';
import '../../Data/repositories/patient_repository.dart'; 

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;
  
  const PatientDetailsScreen({Key? key, required this.patient}) : super(key: key);

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final appointmentRepo = AppointmentRepository();
  final patientRepo = PatientRepository();

  // Variabile pentru Editare
  bool _isEditing = false;
  bool _isLoading = false;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late Patient _currentPatient; // Păstrăm pacientul aici pentru a-i actualiza datele pe ecran

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
    // Inițializăm controllerele cu datele actuale ale pacientului
    _phoneController = TextEditingController(text: _currentPatient.phone);
    _emailController = TextEditingController(text: _currentPatient.email);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _savePatientDetails() async {
    setState(() => _isLoading = true);

    // Creăm un obiect nou cu datele actualizate
    final updatedPatient = Patient(
      id: _currentPatient.id,
      name: _currentPatient.name, // Numele îl lăsăm neschimbat aici
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );

    try {
      // Deoarece addPatient folosește .doc(id).set(), va funcționa perfect ca un UPDATE 
      // pentru că ID-ul este deja existent în baza de date!
      await patientRepo.addPatient(updatedPatient);

      setState(() {
        _currentPatient = updatedPatient; // Actualizăm UI-ul
        _isEditing = false;               // Închidem modul de editare
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datele pacientului au fost actualizate!')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare la salvare: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Fișă Pacient', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.bordeaux,
        foregroundColor: AppColors.cream,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CARTEA DE VIZITĂ A PACIENTULUI
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.bordeaux.withOpacity(0.1),
                      child: Text(
                        _currentPatient.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.bordeaux),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(_currentPatient.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    // -- SECȚIUNEA DE AFIȘARE SAU EDITARE --
                    if (_isEditing) ...[
                      // MODUL DE EDITARE
                      TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Număr de telefon',
                          prefixIcon: const Icon(Icons.phone, color: AppColors.bordeaux),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Adresă de email',
                          prefixIcon: const Icon(Icons.email, color: AppColors.bordeaux),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              // Resetăm câmpurile dacă dă cancel
                              _phoneController.text = _currentPatient.phone;
                              _emailController.text = _currentPatient.email;
                              setState(() => _isEditing = false);
                            },
                            child: const Text('Anulează', style: TextStyle(color: Colors.grey)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _savePatientDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bordeaux,
                              foregroundColor: AppColors.cream,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream))
                                : const Text('Salvează'),
                          ),
                        ],
                      )
                    ] else ...[
                      // MODUL DE VIZUALIZARE STATIC
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, size: 18, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(_currentPatient.phone.isNotEmpty ? _currentPatient.phone : 'Nespecificat', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.email, size: 18, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(_currentPatient.email.isNotEmpty ? _currentPatient.email : 'Nespecificat', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                        ],
                      ),
                    ],
                  ],
                ),
                
                // BUTONUL DE EDITARE (CREION) DIN DREAPTA SUS
                if (!_isEditing)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () => setState(() => _isEditing = true),
                      tooltip: 'Editează datele pacientului',
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 2. ISTORICUL PROGRAMĂRILOR (Rămâne neschimbat)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Istoric Servicii', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.bordeaux)),
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: StreamBuilder<List<Appointment>>(
              stream: appointmentRepo.getPatientAppointments(_currentPatient.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.bordeaux));
                }
                
                final appointments = snapshot.data ?? [];

                if (appointments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Nu există istoric pentru acest pacient.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final app = appointments[index];
                    
                    Color statusColor = Colors.blue;
                    if (app.status == 'finalizat') statusColor = Colors.green;
                    if (app.status == 'anulat') statusColor = Colors.red;

                    return Card(
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent, 
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center, 
                          children: [
                            // 1. DATA
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  Text(DateFormat('dd').format(app.time), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.bordeaux)),
                                  Text(DateFormat('MMM').format(app.time), style: const TextStyle(fontSize: 18, color: AppColors.bordeaux)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // 2. SERVICIU & DETALII
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(app.service, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    app.reason.isNotEmpty ? app.reason : 'Fără detalii suplimentare', 
                                    style: TextStyle(color: Colors.grey[700], fontSize: 18),
                                    maxLines: 2, 
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 3. STATUS & DURATĂ
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end, 
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text(app.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: Colors.grey[700]),
                                    const SizedBox(width: 4),
                                    Text('${app.duration} min', style: TextStyle(color: Colors.grey[700], fontSize: 18, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
}