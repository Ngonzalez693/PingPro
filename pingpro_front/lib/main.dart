import 'package:flutter/material.dart';
import 'package:pingpro_front/screens/pingpro_exercises_screen.dart';
import 'package:pingpro_front/screens/pingpro_home_screen.dart';
import 'package:pingpro_front/screens/pingpro_create_screen.dart';
import 'package:pingpro_front/screens/pingpro_trainings_screen.dart';
import 'package:pingpro_front/screens/pingpro_profile_screen.dart';
import 'package:pingpro_front/widgets/custom_bottom_navigation.dart';
import 'package:pingpro_front/core/app_colors.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});
  @override
  State createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    PingproHomeScreen(),
    PingproExercisesScreen(),
    PingproCreateScreen(),
    PingproTrainingsScreen(),
    PingproProfileScreen(),
  ];

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PingPro',
      theme: ThemeData(scaffoldBackgroundColor: AppColors.background),
      home: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: CustomBottomNavigation(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}
