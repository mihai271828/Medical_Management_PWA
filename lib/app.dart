import 'package:flutter/material.dart';
import 'UI/home/home_screen.dart';
import 'app_contants.dart';
import 'UI/shared/widgets/navigation_bar/nav_bar.dart';

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
    const AnalyticsScreen(),
    const SettingsScreen(),
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
        title: const Text('Semen Vitae Medical',
              style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
              color:AppColors.cream ,
            ),
        ),
        
        backgroundColor: AppColors.bordeaux,
        foregroundColor: AppColors.cream,
        actions: [
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
      ),
    );
  }
}







// Placeholder screens - replace these later
class PatientsScreen extends StatelessWidget {
  const PatientsScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: const Center(child: Text('Patients Screen')),
    );
  }
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('Analytics Screen')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: const Center(child: Text('Settings Screen')),
    );
  }
}