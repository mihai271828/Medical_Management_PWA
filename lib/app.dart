import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; 
import 'UI/home/home_screen.dart';
import 'UI/patients/patients_screen.dart';
import 'package:medical_management_pwa/UI/subscriptions/subscriptions_screen.dart';
import 'app_contants.dart';
import 'UI/shared/widgets/navigation_bar/nav_bar.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({Key? key}) : super(key: key);

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentIndex = 0;
  
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;


  final List<Widget> _screens = [
    const HomeScreen(),
    const PatientsScreen(),
    const SubscriptionsScreen(),
    const AnalyticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    
    Connectivity().checkConnectivity().then(_updateConnectionStatus);
    
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    
    bool isCurrentlyOffline = result.contains(ConnectivityResult.none);
    
    if (_isOffline != isCurrentlyOffline) {
      if (mounted) {
        setState(() {
          _isOffline = isCurrentlyOffline;
        });
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      
      appBar: AppBar(
        toolbarHeight: _isOffline ? 25 : 10, 
        backgroundColor: AppColors.bordeaux,
        
        elevation: 0, 
        systemOverlayStyle: SystemUiOverlayStyle.light, 
        
        
        title: _isOffline 
          ? const Padding(
                padding: EdgeInsets.only(bottom: 8.0), 
                child: Text(
                  'Sunteți offline',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              )
            : null,
        centerTitle: true,),
      
    );
  }
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Analytics Screen', style: TextStyle(fontSize: 18)),
    );
  }
}