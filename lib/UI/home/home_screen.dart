import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:medical_management_pwa/UI/shared/widgets/home_page/statisticalItem.dart';
import '../../app_contants.dart';
import '../../Data/models/appointment_model.dart'; 
import '../appointment/add_appointment_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();
  final CollectionReference _appointmentsRef =
    FirebaseFirestore.instance.collection('appointments');

  
  void _checkAndAutoComplete(List<Appointment> appointments) {
    final now = DateTime.now();

    for (var appointment in appointments) {
      final endTime = appointment.time.add(Duration(minutes: appointment.duration));

      
      if (appointment.status == 'programat' && now.isAfter(endTime)) {
        
        _appointmentsRef.doc(appointment.id).update({'status': 'finalizat'});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: AppColors.cream,
      
      // We wrap the body in a StreamBuilder to listen to DB changes
      body: StreamBuilder<QuerySnapshot>(
        stream: _appointmentsRef
            .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('time', isLessThan: Timestamp.fromDate(endOfDay))
            .orderBy('time')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Convert raw DB data to our clean List<Appointment>
          final appointments = snapshot.data!.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .toList();

          _checkAndAutoComplete(appointments);

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildDateSelector(),
                
                // Pass the real data to the stats card
                _buildStatsCard(appointments),
                
                _buildAppointmentsList(appointments),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.bordeaux.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 28),
                color: AppColors.bordeaux,
                onPressed: () {
                  setState(() {
                    selectedDate = selectedDate.subtract(const Duration(days: 1));
                  });
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      
                      DateFormat('EEEE', 'ro_RO').format(selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                     
                      DateFormat('d MMMM yyyy', 'ro_RO').format(selectedDate),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF800020),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 28),
                color: const Color(0xFF800020),
                onPressed: () {
                  setState(() {
                    selectedDate = selectedDate.add(const Duration(days: 1));
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                locale: const Locale('ro', 'RO'), 
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF800020),
                        onPrimary: Color(0xFFFFFDD0),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() {
                  selectedDate = date;
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF800020).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.calendar_today, size: 18, color: Color(0xFF800020)),
                  SizedBox(width: 8),
                  Text(
                    'Selectează Data',
                    style: TextStyle(
                      color: Color(0xFF800020),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildStatsCard(List<Appointment> appointments) {
    // Calculate stats dynamically based on Romanian status strings
    final total = appointments.length;
    final scheduled = appointments.where((a) => a.status == 'programat').length;
    final completed = appointments.where((a) => a.status == 'finalizat').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bordeaux,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF800020).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Statisticalitem(
              icon: Icons.event_note,
              label: 'Total',
              value: total.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.cream.withOpacity(0.3),
          ),
          Expanded(
            child: Statisticalitem(
              icon: Icons.schedule,
              label: 'Programate',
              value: scheduled.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.cream.withOpacity(0.3),
          ),
          Expanded(
            child: Statisticalitem(
              icon: Icons.check_circle,
              label: 'Finalizate',
              value: completed.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(List<Appointment> appointments) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nu există programări',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Apasă butonul + pentru a adăuga',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildAppointmentCard(appointments[index]);
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    // Check for Romanian status strings
    Color statusColor = appointment.status == 'finalizat'
        ? Colors.green
        : appointment.status == 'anulat'
            ? Colors.red
            : AppColors.bordeaux;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AddAppointmentDialog(
                selectedDate: selectedDate,
                appointment: appointment, 
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 70,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            '${DateFormat('HH:mm').format(appointment.time)} • ${appointment.duration}min',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (appointment.reason.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.notes_outlined, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                appointment.reason,
                                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    
                    appointment.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
  return FloatingActionButton.extended(
    onPressed: () {
      showDialog(
        context: context,
        builder: (context) => AddAppointmentDialog(selectedDate: selectedDate),
      );
    },
    backgroundColor: AppColors.bordeaux,
    foregroundColor: AppColors.cream,
    elevation: 4,
    icon: const Icon(Icons.add),
    label: const Text(
      'Programare Nouă',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    ),
  );
}
}