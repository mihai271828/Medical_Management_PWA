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

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  DateTime _selectedDate = DateTime.now();
  bool _isCalendarExpanded = false;
  
  // 1. Caching pentru Stream ca să nu se re-creeze la deschiderea calendarului
  late Stream<QuerySnapshot> _dailyAppointmentsStream;
  final CollectionReference _appointmentsRef = FirebaseFirestore.instance.collection('appointments');

  // 2. Formatters declarate static pentru eficiență maximă
  static final DateFormat _dayFormatter = DateFormat('EEEE', 'ro_RO');
  static final DateFormat _monthFormatter = DateFormat('MMMM', 'ro_RO');
  static final DateFormat _timeFormatter = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _updateStream();
  }

  // Actualizăm stream-ul DOAR când schimbăm data efectiv, nu la orice setState
  void _updateStream() {
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    _dailyAppointmentsStream = _appointmentsRef
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('time', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('time')
        .snapshots();
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _isCalendarExpanded = false;
      _updateStream(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Pentru AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: StreamBuilder<QuerySnapshot>(
        stream: _dailyAppointmentsStream,
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

          // AVERTISMENT: Asigură-te că acest serviciu NU face loop infinit! 
          // Recomandat este să pui această logică într-un serviciu separat (ex: pe onStart-ul aplicației)
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

  Widget _buildDateSelector() {
    String dayName = _dayFormatter.format(_selectedDate);
    String capitalizedDay = dayName.isNotEmpty ? '${dayName[0].toUpperCase()}${dayName.substring(1)}' : '';
    
    String monthName = _monthFormatter.format(_selectedDate);
    String capitalizedMonth = monthName.isNotEmpty ? '${monthName[0].toUpperCase()}${monthName.substring(1)}' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _onDateChanged(_selectedDate.subtract(const Duration(days: 1))),
                icon: const Icon(Icons.chevron_left, color: AppColors.bordeaux, size: 32),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
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
                          '$capitalizedDay, ${_selectedDate.day} $capitalizedMonth',
                          style: const TextStyle(
                            fontSize: 22,
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
              IconButton(
                onPressed: () => _onDateChanged(_selectedDate.add(const Duration(days: 1))),
                icon: const Icon(Icons.chevron_right, color: AppColors.bordeaux, size: 32),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isCalendarExpanded ? _buildInlineCalendar() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

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
          initialDate: _selectedDate,
          firstDate: DateTime(2020), 
          lastDate: DateTime(2030),
          onDateChanged: _onDateChanged, // Utilizează funcția creată mai sus
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
          Expanded(child: Statisticalitem(icon: Icons.event_note, label: 'Total', value: total.toString())),
          Container(width: 1, height: 40, color: AppColors.cream.withOpacity(0.3)),
          Expanded(child: Statisticalitem(icon: Icons.schedule, label: 'Programate', value: scheduled.toString())),
          Container(width: 1, height: 40, color: AppColors.cream.withOpacity(0.3)),
          Expanded(child: Statisticalitem(icon: Icons.check_circle, label: 'Finalizate', value: completed.toString())),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(List<Appointment> appointments) {
    if (appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80, bottom: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white, 
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
                ),
                child: Icon(Icons.calendar_today_outlined, size: 50, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 32),
              const Text(
                'Nu există programări',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4A4A4A), 
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Algoritm Optimizat O(N) pentru intervale orare
    // În loc să interogăm lista cu .where pentru fiecare oră, pre-mapăm datele
    Map<DateTime, List<Appointment>> startingAppsMap = {};
    Map<DateTime, List<Appointment>> ongoingAppsMap = {};
    Set<DateTime> timesToShow = {};

    for (var app in appointments) {
      timesToShow.add(app.time);
      startingAppsMap.putIfAbsent(app.time, () => []).add(app);

      int nextSlotMinute = app.time.minute < 30 ? 30 : 0;
      int nextSlotHour = app.time.minute < 30 ? app.time.hour : app.time.hour + 1;
      DateTime runningTime = DateTime(
        app.time.year, app.time.month, app.time.day,
        nextSlotHour, nextSlotMinute,
      );
      DateTime appEndTime = app.time.add(Duration(minutes: app.duration));

      while (runningTime.isBefore(appEndTime)) {
        timesToShow.add(runningTime);
        ongoingAppsMap.putIfAbsent(runningTime, () => []).add(app);
        runningTime = runningTime.add(const Duration(minutes: 30));
      }
    }

    List<DateTime> sortedTimes = timesToShow.toList()..sort();
    List<Widget> timeSlots = [];

    for (var time in sortedTimes) {
      final starting = startingAppsMap[time] ?? [];
      final ongoing = ongoingAppsMap[time] ?? [];
      timeSlots.add(_buildTimeSlotRow(time, starting, ongoing));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(children: timeSlots),
    );
  }

  Widget _buildTimeSlotRow(DateTime slotTime, List<Appointment> startingApps, List<Appointment> ongoingApps) {
    final String timeString = _timeFormatter.format(slotTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: AppColors.bordeaux),
              const SizedBox(width: 8),
              Text(
                timeString,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.bordeaux),
              ),
              const SizedBox(width: 12),
              Expanded(child: Divider(color: AppColors.bordeaux.withOpacity(0.2), thickness: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          ...startingApps.map((app) => InkWell(
            onTap: () => _openEditDialog(app), 
            child: BusySlotCard(appointment: app, slotTime: slotTime, selectedDate: _selectedDate),
          )),
          ...ongoingApps.map((app) => _buildOngoingSlotCard(app, slotTime)),
        ],
      ),
    );
  }

  void _openEditDialog(Appointment app) {
    showDialog(
      context: context,
      builder: (context) => AddAppointmentDialog(selectedDate: _selectedDate, appointment: app),
    );
  }

  Widget _buildOngoingSlotCard(Appointment app, DateTime slotTime) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(Colors.grey.shade400.withOpacity(0.6), BlendMode.srcATop),
      child: Opacity(
        opacity: 0.85, 
        child: BusySlotCard(appointment: app, slotTime: slotTime, selectedDate: _selectedDate),
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
          onTap: () => showDialog(
            context: context,
            builder: (context) => AddAppointmentDialog(selectedDate: _selectedDate),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, color: AppColors.cream, size: 24),
              SizedBox(width: 8),
              Text(
                'Programare Nouă',
                style: TextStyle(color: AppColors.cream, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}