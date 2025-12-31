import 'package:flutter/material.dart';
import 'nav_item.dart';
import 'package:medical_management_pwa/app_contants.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex
    , required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          color:  AppColors.bordeaux),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              NavItem(
                icon: Icons.calendar_today,
                label: 'Calendar',
                index: 0,
                isSelected: currentIndex == 0,
                onTap: onTap,
              ),
              NavItem(
                icon: Icons.people_outline,
                label: 'Pacienți',
                index: 1,
                isSelected: currentIndex == 1,
                onTap: onTap,
              ),
              NavItem(
                icon: Icons.analytics_outlined,
                label: 'Statistici',
                index: 2,
                isSelected: currentIndex == 2,
                onTap: onTap,
              ),
              NavItem(
                icon: Icons.settings_outlined,
                label: 'Setări',
                index: 3,
                isSelected: currentIndex == 3,
                onTap: onTap,
              ),
              
            ],
          ),
        );
    
    
  }

  
    
}