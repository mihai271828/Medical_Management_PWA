import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_contants.dart';
import '../../Data/models/appointment_model.dart';
import '../../Data/models/patient_model.dart';
import '../../Data/models/subscription_model.dart';
import '../../Data/repositories/appointment_repositorty.dart';
import '../../Data/repositories/subsctiption_repository.dart';
import '../../Data/repositories/patient_repository.dart';

class AddAppointmentDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Appointment? appointment;

  const AddAppointmentDialog({
    Key? key,
    required this.selectedDate,
    this.appointment,
  }) : super(key: key);

  @override
  State<AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();

  // Repositories
  final _repository = AppointmentRepository();
  final _subscriptionRepo = SubscriptionRepository();
  final _patientRepo = PatientRepository();

  // Variabile State
  List<Patient> _allPatients = [];
  Patient? _selectedPatient;
  late TextEditingController _nameController;
  late TextEditingController _reasonController;
  late TimeOfDay _selectedTime;
  late int _duration;
  late String _status;
  bool _isLoading = false;

  final List<String> _servicesList = [
    'Acupunctură - consultație',
    'Acupunctură - ședință',
    'Acupunctură - abonament',
    'Infiltrație',
    'Masaj terapeutic',
    'Masaj deep-tissue',
    'Reflexoterapie',
  ];

  String? _selectedService;
  Subscription? _activeSubscription;
  bool _isCheckingSubscription = false;

  bool _isSelectingService = false;

  @override
  void initState() {
    super.initState();
    _loadPatients();

    if (widget.appointment != null) {
      final app = widget.appointment!;
      _selectedPatient = Patient(id: app.patientId, name: app.patientName);
      _nameController = TextEditingController(text: app.patientName);
      _reasonController = TextEditingController(text: app.reason);
      _selectedTime = TimeOfDay.fromDateTime(app.time);
      _duration = app.duration;
      _status = app.status;
      _selectedService = app.service;

      _checkActiveSubscription();
    } else {
      _nameController = TextEditingController();
      _reasonController = TextEditingController();
      _selectedTime = const TimeOfDay(hour: 8, minute: 30);
      _duration = 30;
      _status = 'programat';
      _selectedService = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await _patientRepo.getAllPatients();
      if (mounted) {
        setState(() {
          _allPatients = patients;
        });
      }
    } catch (e) {
      debugPrint('Eroare la încărcarea pacienților: $e');
    }
  }

  Future<void> _checkActiveSubscription() async {
    if (_selectedService == null) return;

    if (_selectedService!.toLowerCase().contains('abonament')) {
      if (_selectedPatient == null) {
        setState(() {
          _isCheckingSubscription = false;
          _activeSubscription = null;
        });
        return;
      }

      setState(() => _isCheckingSubscription = true);

      try {
        final sub = await _subscriptionRepo.getActiveSubscription(
          _selectedPatient!.id,
          _selectedService!,
        );

        if (mounted) {
          setState(() {
            _activeSubscription = sub;
            _isCheckingSubscription = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isCheckingSubscription = false);
        }
        debugPrint('Eroare la verificarea abonamentului: $e');
      }
    } else {
      setState(() => _activeSubscription = null);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    int currentMinute = _selectedTime.minute;
    int roundedMinute = (currentMinute / 15).round() * 15;
    if (roundedMinute == 60) roundedMinute = 45;

    TimeOfDay initialTime = TimeOfDay(
      hour: _selectedTime.hour,
      minute: roundedMinute,
    );
    TimeOfDay tempTime = initialTime;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext builder) {
        return SizedBox(
          height: 400,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Alege Ora',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.bordeaux,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Gata',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.bordeaux,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                      initialTime.hour,
                      initialTime.minute,
                    ),
                    minuteInterval: 15,
                    onDateTimeChanged: (DateTime newDateTime) {
                      tempTime = TimeOfDay.fromDateTime(newDateTime);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    setState(() {
      _selectedTime = tempTime;
    });
  }

  // OPTIMIZAT PENTRU OFFLINE 
  void _saveAppointment() {
    if (_selectedService == null) {
      _showError('Vă rugăm să selectați un serviciu');
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String finalPatientId = '';
      String finalPatientName = _nameController.text;

      if (_selectedPatient != null) {
        finalPatientId = _selectedPatient!.id;
      } else {
        
        final newPatientRef = FirebaseFirestore.instance.collection('patients').doc();
        final newPatient = Patient(id: newPatientRef.id, name: finalPatientName);
        _patientRepo.addPatient(newPatient); 
        finalPatientId = newPatient.id;
      }

      final appointmentDateTime = DateTime(
        widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day,
        _selectedTime.hour, _selectedTime.minute,
      );

      final endTime = appointmentDateTime.add(Duration(minutes: _duration));
      final now = DateTime.now();

      
      if (widget.appointment == null) {
        if (now.isAfter(endTime)) {
          _status = 'finalizat'; 
        } else {
          _status = 'programat';
        }
      }

      String? subId = _activeSubscription?.id ?? widget.appointment?.subscriptionId;

      final newAppointment = Appointment(
        id: widget.appointment?.id ?? '',
        patientId: finalPatientId,
        patientName: finalPatientName,
        time: appointmentDateTime,
        duration: _duration,
        reason: _reasonController.text,
        status: _status,
        service: _selectedService!,
        subscriptionId: subId,
      );

      try {
        
        bool wasFinalizat = widget.appointment?.status == 'finalizat';
        bool isNowFinalizat = _status == 'finalizat';
        bool hadSubscriptionBefore = widget.appointment?.subscriptionId != null && widget.appointment!.subscriptionId!.isNotEmpty;
        bool hasSubscriptionNow = subId != null && subId.isNotEmpty;

        
        void updateSubscriptionSessions(String targetSubId, int amount) {
          int current = _activeSubscription?.usedSessions ?? 0;
          int total = _activeSubscription?.totalSessions ?? 10;
          
          Map<String, dynamic> updates = {
            'usedSessions': FieldValue.increment(amount)
          };
          
          if (amount > 0 && (current + amount) >= total) {
            updates['status'] = 'finalizat';
            updates['completedAt'] = Timestamp.fromDate(appointmentDateTime); 
          } 

          else if (amount < 0 && current >= total && (current + amount) < total) {
            updates['status'] = 'activ';
            updates['completedAt'] = null; 
          }
          
          FirebaseFirestore.instance.collection('subscriptions').doc(targetSubId).update(updates);
        }

        if (widget.appointment == null) {
          
          _repository.addAppointment(newAppointment);
          if (isNowFinalizat && hasSubscriptionNow) {
            updateSubscriptionSessions(subId, 1);
          }
        } else {
         
          _repository.updateAppointment(newAppointment);
          
          if (!wasFinalizat && isNowFinalizat && hasSubscriptionNow) {
            updateSubscriptionSessions(subId, 1);
          }
          else if (wasFinalizat && !isNowFinalizat && hadSubscriptionBefore) {
            updateSubscriptionSessions(widget.appointment!.subscriptionId!, -1);
          }
          else if (wasFinalizat && isNowFinalizat && !hadSubscriptionBefore && hasSubscriptionNow) {
            updateSubscriptionSessions(subId, 1);
          }
        }

        if (mounted) {
  setState(() => _isLoading = false);
  Navigator.pop(context);
}; 
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  void _deleteAppointment() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge Programarea'),
        content: const Text('Ești sigur că vrei să ștergi această programare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Șterge', style: TextStyle(color: AppColors.bordeaux)),
          ),
        ],
      ),
    ).then((confirm) {
      if (confirm == true && widget.appointment != null) {
        setState(() => _isLoading = true);
        try {
          _repository.deleteAppointment(widget.appointment!.id);
          if (mounted) Navigator.pop(context);
        } catch (e) {
          _showError(e.toString());
        }
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare: $message')));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.appointment != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.hardEdge,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _isSelectingService
            ? _buildServiceSelectionView()
            : _buildMainForm(isEditing),
      ),
    );
  }

  Widget _buildMainForm(bool isEditing) {
    return Padding(
      key: const ValueKey('MainForm'),
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Editează Programarea' : 'Programare Nouă',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.bordeaux,
                    ),
                  ),
                  if (isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.bordeaux),
                      onPressed: _isLoading ? null : _deleteAppointment,
                      tooltip: 'Șterge',
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // 1. AUTOCOMPLETE PENTRU PACIENT
              Autocomplete<Patient>(
                initialValue: TextEditingValue(text: _nameController.text),
                displayStringForOption: (Patient option) => option.name,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Patient>.empty();
                  }
                  return _allPatients.where((Patient patient) {
                    return patient.name.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (Patient selection) {
                  setState(() {
                    _selectedPatient = selection;
                    _nameController.text = selection.name;
                  });
                  _checkActiveSubscription();
                },
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  if (textEditingController.text != _nameController.text) {
                    textEditingController.text = _nameController.text;
                  }
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: _inputDecoration('Nume Pacient', Icons.person),
                    onChanged: (val) {
                      setState(() {
                        _nameController.text = val;
                        if (_selectedPatient != null && val != _selectedPatient!.name) {
                          _selectedPatient = null;
                          _activeSubscription = null;
                          _selectedService = null;
                        }
                        if (val.trim().isEmpty) {
                          _selectedService = null;
                          _activeSubscription = null;
                        }
                      });
                    },
                    validator: (value) => value!.isEmpty ? 'Introduceți numele' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. MOTIV
              TextFormField(
                controller: _reasonController,
                decoration: _inputDecoration('Motiv / Detalii', Icons.notes),
              ),
              const SizedBox(height: 16),

              // 3. BUTON PENTRU SERVICIU
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _nameController.text.trim().isEmpty
                        ? null
                        : () => setState(() => _isSelectingService = true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                        color: _nameController.text.trim().isEmpty
                            ? Colors.grey.shade50
                            : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            color: _nameController.text.trim().isEmpty
                                ? Colors.grey
                                : AppColors.bordeaux,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedService ?? 'Selectează Serviciul',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedService == null ? Colors.grey[600] : Colors.black,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  if (_nameController.text.trim().isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        'Introduceți întâi numele pacientului',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
                      ),
                    ),
                ],
              ),

              // 4. BANNER ABONAMENT
              if (_selectedService != null &&
                  _selectedService!.toLowerCase().contains('abonament')) ...[
                const SizedBox(height: 8),
                if (_isCheckingSubscription)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text('Verificăm abonamentele...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  )
                else if (_activeSubscription != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isEditing 
                                ? 'Abonament asociat (${_activeSubscription!.usedSessions} din ${_activeSubscription!.totalSessions} efectuate)'
                                : 'Abonament activ: Urmează ședința ${_activeSubscription!.usedSessions + 1} din ${_activeSubscription!.totalSessions}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      border: Border.all(color: AppColors.bordeaux.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.bordeaux, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Acest pacient nu are un abonament activ.',
                                style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            // OPTIMIZAT PENTRU OFFLINE - Am scos async/await
                            onPressed: () {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _isLoading = true);

                              try {
                                String finalPatientName = _nameController.text.trim();
                                
                                // 1. Creăm Pacientul FĂRĂ await
                                if (_selectedPatient == null) {
                                  final newPatientRef = FirebaseFirestore.instance.collection('patients').doc();
                                  final newPatient = Patient(id: newPatientRef.id, name: finalPatientName);
                                  _patientRepo.addPatient(newPatient);
                                  _selectedPatient = newPatient;
                                }
                                
                                // 2. Creăm Abonamentul Nou FĂRĂ await
                                final newSubRef = FirebaseFirestore.instance.collection('subscriptions').doc();
                                final newSubscription = Subscription(
                                  id: newSubRef.id,
                                  patientId: _selectedPatient!.id,
                                  patientName: finalPatientName,
                                  service: _selectedService!,
                                  totalSessions: 10,
                                  usedSessions: 0,
                                  status: 'activ',
                                  createdAt: DateTime.now(),
                                  totalPrice: 1500.0,
                                  amountPaid: 0.0,
                                );
                                _subscriptionRepo.addSubscription(newSubscription);

                                setState(() {
                                  _activeSubscription = newSubscription;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Abonament creat cu succes!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );

                                // 3. Salvăm Programarea (închide dialogul automat)
                                _saveAppointment();

                              } catch (e) {
                                if (mounted) {
                                  _showError(e.toString());
                                }
                              }
                            },
                            icon: const Icon(Icons.add_card, size: 18),
                            label: const Text('Creează Abonament Nou'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.bordeaux,
                              side: const BorderSide(color: AppColors.bordeaux),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 16),

              // 5. ORA (Doar la programare nouă)
              if (!isEditing) ...[
                InkWell(
                  onTap: () => _selectTime(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: AppColors.bordeaux, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 6. DURATA
              DropdownButtonFormField<int>(
                value: _duration,
                decoration: _inputDecoration('Durata', Icons.timer),
                items: [15, 30, 45, 60, 90].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value min'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _duration = val!),
              ),
              const SizedBox(height: 16),

              // 7. STATUS (Doar la editare)
              if (isEditing)
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: _inputDecoration('Status', Icons.flag),
                  items: ['programat', 'finalizat', 'anulat'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _status = val!),
                ),

              const SizedBox(height: 32),

              // 8. BUTOANE
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Anulează', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bordeaux,
                      foregroundColor: AppColors.cream,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream),
                          )
                        : Text(isEditing ? 'Actualizează' : 'Salvează'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceSelectionView() {
    return Padding(
      key: const ValueKey('ServiceList'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.bordeaux),
                onPressed: () => setState(() => _isSelectingService = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              const Text(
                'Alege Serviciul',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.bordeaux),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: _servicesList.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 1),
            itemBuilder: (context, index) {
              final service = _servicesList[index];
              final isSelected = _selectedService == service;

              return ListTile(
                title: Text(
                  service,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.bordeaux : Colors.black87,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.bordeaux) : null,
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  setState(() {
                    _selectedService = service;
                    _isSelectingService = false;
                  });
                  _checkActiveSubscription();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600]),
      prefixIcon: Icon(icon, color: AppColors.bordeaux),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.bordeaux, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}