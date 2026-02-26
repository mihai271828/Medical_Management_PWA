import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:medical_management_pwa/UI/shared/widgets/home_page/statistical_Item.dart';
import '../../app_contants.dart';
import '../../Data/models/appointment_model.dart'; 
import '../appointment/add_appointment_dialog.dart';
import '../shared/widgets/home_page/card.dart';
import '../../Domain/subscription_service/appointment_sync_service.dart';






class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();
  bool _isCalendarExpanded = false;
  final CollectionReference _appointmentsRef = FirebaseFirestore.instance.collection('appointments');

  
  

  @override
  Widget build(BuildContext context) {
    
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return Scaffold(
      backgroundColor: AppColors.cream,
      
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _appointmentsRef
            .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(  startOfDay))
            .where('time', isLessThan: Timestamp.fromDate(endOfDay))
            .orderBy('time')
            .snapshots(includeMetadataChanges: true),
        builder: (context, snapshot) {

          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }


          final List<Appointment> appointments = [];
          for (var doc in snapshot.data!.docs) {
            try {
              appointments.add(Appointment.fromFirestore(doc));
            } catch (e) {
              debugPrint('Document ignorat (eroare cache) ID: ${doc.id}');
            }
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
                  AppointmentSyncService.checkAndAutoUpdatePastAppointments(appointments);
                });

          return SingleChildScrollView(
            child: Column(
              children: [


               
                _buildDateSelector(),
                
               
                _buildStatsCard(appointments),
                
                
                _buildAppointmentsList(appointments),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildAppleStyleButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // 1. HEADER-UL MODERN 
  Widget _buildDateSelector() {
    String dayName = DateFormat('EEEE', 'ro_RO').format(selectedDate);
    String capitalizedDay = dayName.isNotEmpty ? '${dayName[0].toUpperCase()}${dayName.substring(1)}' : '';
    
    String monthName = DateFormat('MMMM', 'ro_RO').format(selectedDate);
    String capitalizedMonth = monthName.isNotEmpty ? '${monthName[0].toUpperCase()}${monthName.substring(1)}' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedDate = selectedDate.subtract(const Duration(days: 1));
                    _isCalendarExpanded = false; // Ascundem calendarul dacă era deschis
                  });
                },
                icon: const Icon(Icons.chevron_left, color: AppColors.bordeaux, size: 32),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(), // Face zona de tap mai compactă
              ),

              // Butonul central (Data) care deschide/închide calendarul complet
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$capitalizedDay, ${selectedDate.day} $capitalizedMonth',
                          style: const TextStyle(
                            fontSize: 22, // Am micșorat puțin fontul ca să încapă perfect cu săgețile
                            fontWeight: FontWeight.w800, 
                            color: AppColors.bordeaux,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isCalendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: AppColors.bordeaux,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Săgeata Dreapta
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedDate = selectedDate.add(const Duration(days: 1));
                    _isCalendarExpanded = false;
                  });
                },
                icon: const Icon(Icons.chevron_right, color: AppColors.bordeaux, size: 32),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          // Calendarul complet inline
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isCalendarExpanded ? _buildInlineCalendar() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  //  CALENDARUL INLINE CARE APARE LA CLICK
  Widget _buildInlineCalendar() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.bordeaux.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.bordeaux, 
            onPrimary: Colors.white, 
            onSurface: Colors.black87, 
          ),
        ),
        child: CalendarDatePicker(
          initialDate: selectedDate,
          
          firstDate: DateTime(2020), 
          lastDate: DateTime(2030),
          onDateChanged: (DateTime newDate) {
            setState(() {
              selectedDate = newDate;
              _isCalendarExpanded = false; 
            });
          },
        ),
      ),
    );
  }
  
  Widget _buildStatsCard(List<Appointment> appointments) {
    final total = appointments.length;
    final scheduled = appointments.where((a) => a.status == 'programat').length;
    final completed = appointments.where((a) => a.status == 'finalizat').length;

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(10),
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
  // Dacă nu avem nicio programare, afișăm un mesaj sugestiv
  if (appointments.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 50),
        child: Text(
          'Nu există programări pentru această zi.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }

  Set<DateTime> timesToShow = {};


  for (var app in appointments) {
    
    timesToShow.add(app.time);

    
    DateTime runningTime = app.time;
    DateTime appEndTime = app.time.add(Duration(minutes: app.duration));

    
    while (runningTime.add(const Duration(minutes: 30)).isBefore(appEndTime)) {
      runningTime = runningTime.add(const Duration(minutes: 30));
      timesToShow.add(runningTime);
    }
  }

  // 3. Sortăm cronologic orele colectate
  List<DateTime> sortedTimes = timesToShow.toList()..sort();

  List<Widget> timeSlots = [];

  for (var time in sortedTimes) {
    
    final startingApps = appointments.where((app) => app.time.isAtSameMomentAs(time)).toList();

    
    final ongoingApps = appointments.where((app) {
      final appEndTime = app.time.add(Duration(minutes: app.duration));
      return app.time.isBefore(time) && appEndTime.isAfter(time);
    }).toList();

    timeSlots.add(_buildTimeSlotRow(time, startingApps, ongoingApps));
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: Column(
      children: timeSlots,
    ),
  );
}

  Widget _buildTimeSlotRow(DateTime slotTime, List<Appointment> startingApps, List<Appointment> ongoingApps) {
  final String timeString = DateFormat('HH:mm').format(slotTime);

  return Padding(
    padding: const EdgeInsets.only(bottom: 24.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header-ul orei (Rămâne neschimbat)
        Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: AppColors.bordeaux),
            const SizedBox(width: 8),
            Text(
              timeString,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: AppColors.bordeaux,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: AppColors.bordeaux.withOpacity(0.2), thickness: 1.5)),
          ],
        ),
        const SizedBox(height: 12),
        
        // CARDURI NORMALE (Care încep acum)
        ...startingApps.map((app) => InkWell(
          onTap: () => _openEditDialog(app), 
          child: BusySlotCard(
            appointment: app,
            slotTime: slotTime,
            selectedDate: selectedDate,
          ),
        )).toList(),

        //  CARDURI GRI (În desfășurare)
        ...ongoingApps.map((app) => InkWell(
          child: _buildOngoingSlotCard(app, slotTime),
        )).toList(),
      ],
    ),
  );
}

void _openEditDialog(Appointment app) {
  showDialog(
    context: context,
    builder: (context) => AddAppointmentDialog(
      selectedDate: selectedDate,
      appointment: app, 
    ),
  );
}

  Widget _buildOngoingSlotCard(Appointment app, DateTime slotTime) {
   return ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.grey.shade400.withOpacity(0.6), 
          BlendMode.srcATop, 
        ),
        child: Opacity(
          opacity: 0.85, 
          child: BusySlotCard(
            appointment: app,
            slotTime: slotTime,
            selectedDate: selectedDate, 
          ),
        ),
      );
  }

  

  Widget _buildAppleStyleButton() {
    return Container(
      
      width: MediaQuery.of(context).size.width * 0.85, 
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.bordeaux,
        borderRadius: BorderRadius.circular(28), 
        boxShadow: [
          BoxShadow(
            color: AppColors.bordeaux.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AddAppointmentDialog(selectedDate: selectedDate),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_circle, color: AppColors.cream, size: 24),
              SizedBox(width: 8),
              Text(
                'Programare Nouă',
                style: TextStyle(
                  color: AppColors.cream,
                  fontSize: 18,
                  fontWeight: FontWeight.w600, 
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}