import 'package:flutter/material.dart';
import 'package:medical_management_pwa/UI/subscriptions/subscriptions_screen.dart';
import 'UI/home/home_screen.dart';
import 'UI/subscriptions/subscriptions_screen.dart';
import 'app_contants.dart';
import 'UI/shared/widgets/navigation_bar/nav_bar.dart';
import 'package:flutter/services.dart';
import 'UI/patients/patients_screen.dart';
class AppScaffold extends StatefulWidget {
  const AppScaffold({Key? key}) : super(key: key);

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PatientsScreen(),
    const SubscriptionsScreen(),
    const AnalyticsScreen(),
    
  ];

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
        toolbarHeight: 10, // Îl face invizibil pentru UI-ul tău
        backgroundColor: AppColors.bordeaux, // Colorează zona de notch
        elevation: 0, // Scoate umbra
        systemOverlayStyle: SystemUiOverlayStyle.light, // Face bateria și ceasul albe
      ),
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

