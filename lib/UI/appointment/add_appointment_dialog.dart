import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app_contants.dart';
import '../../Data/models/appointment_model.dart';
import '../../Data/repositories/appointment_repositorty.dart';
import 'package:flutter/cupertino.dart'; 

class AddAppointmentDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Appointment? appointment;
  const AddAppointmentDialog({Key? key, 
  required this.selectedDate, 
  this.appointment}) : super(key: key);

  @override
  State<AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _repository = AppointmentRepository();
  
  
 late TextEditingController _nameController;
  late TextEditingController _reasonController;
  late TimeOfDay _selectedTime;
  late int _duration;
  late String _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if editing, or defaults if new
    if (widget.appointment != null) {
      final app = widget.appointment!;
      _nameController = TextEditingController(text: app.patientName);
      _reasonController = TextEditingController(text: app.reason);
      _selectedTime = TimeOfDay.fromDateTime(app.time);
      _duration = app.duration;
      _status = app.status;
    } else {
      _nameController = TextEditingController();
      _reasonController = TextEditingController();
      _selectedTime = TimeOfDay.now();
      _duration = 30;
      _status = 'programat';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    int currentMinute = _selectedTime.minute;
    int roundedMinute = (currentMinute / 5).round() * 5;
    if (roundedMinute == 60) roundedMinute = 55;

    TimeOfDay initialTime = TimeOfDay(hour: _selectedTime.hour, minute: roundedMinute);
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
              // 1. Header with "Done" button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                          color: AppColors.bordeaux
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 2. The Scroll Wheel
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: Colors.black, // Color of the numbers
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
                      initialTime.minute
                    ),
                    minuteInterval: 5, 
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

  Future<void> _saveAppointment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Create the full DateTime object
      final appointmentDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create model
      final newAppointment = Appointment(
        id: widget.appointment?.id ?? '', // Firestore will generate this
        patientName: _nameController.text,
        time: appointmentDateTime,
        duration: _duration,
        reason: _reasonController.text,
        status: _status, 
      );

      try {
        if (widget.appointment == null) {
          await _repository.addAppointment(newAppointment);
        } else {
          await _repository.updateAppointment(newAppointment);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showError(e.toString());
      }
    }
  }
  Future<void> _deleteAppointment() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
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
    );

    if (confirm == true && widget.appointment != null) {
      setState(() => _isLoading = true);
      try {
        await _repository.deleteAppointment(widget.appointment!.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showError(e.toString());
      }
    }
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
      child: Padding(
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
                
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Nume Pacient', Icons.person),
                  validator: (value) => value!.isEmpty ? 'Introduceți numele' : null,
                ),
                const SizedBox(height: 16),
            
                // Reason
                TextFormField(
                  controller: _reasonController,
                  decoration: _inputDecoration('Motiv / Detalii', Icons.notes),
                ),
                const SizedBox(height: 16),
            
                // Time & Duration
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                
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
            
                // Buttons
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