import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pingpro_front/screens/pingpro_login_screen.dart';
import 'package:pingpro_front/screens/pingpro_register_screen.dart';
import 'package:pingpro_front/screens/pingpro_splash_screen.dart';
import 'package:pingpro_front/screens/pingpro_welcome_screen.dart';
import 'package:pingpro_front/screens/pingpro_home_screen.dart';
import 'package:pingpro_front/screens/pingpro_exercises_screen.dart';
import 'package:pingpro_front/screens/pingpro_create_screen.dart';
import 'package:pingpro_front/screens/pingpro_trainings_screen.dart';
import 'package:pingpro_front/screens/pingpro_profile_screen.dart';
import 'package:pingpro_front/widgets/custom_bottom_navigation.dart';
import 'package:pingpro_front/core/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PingPro',
      theme: ThemeData(scaffoldBackgroundColor: AppColors.background),
      debugShowCheckedModeBanner: false,
      // Empieza en Welcome, y AuthWrapper decidirá siguiente pantalla
      initialRoute: '/welcome',
      routes: {
        '/welcome':  (ctx) => const PingproWelcomeScreen(),
        '/login':    (ctx) => const PingproLoginScreen(),
        '/register': (ctx) => const PingproRegisterScreen(),
        '/splash':   (ctx) => const PingproSplashScreen(),
        '/home':     (ctx) => const HomeNavigation(),
        '/exercises': (ctx) => const PingproExercisesScreen(),
        '/create':    (ctx) => const PingproCreateScreen(),
        '/trainings': (ctx) => const PingproTrainingsScreen(),
        '/profile':   (ctx) => const PingproProfileScreen(),
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeNavigation();
        }
        return const PingproWelcomeScreen();
      },
    );
  }
}

class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});
  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    PingproHomeScreen(),
    PingproExercisesScreen(),
    PingproCreateScreen(),
    PingproTrainingsScreen(),
    PingproProfileScreen(),
  ];
  void _onNavTap(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
