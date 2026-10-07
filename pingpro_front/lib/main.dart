// Punto de entrada de la app y tabla de rutas.
//
// Aquí viven tres piezas:
//   - main():          arranque (dotenv + Firebase) antes de pintar nada.
//   - AuthWrapper:     decide Welcome o Home según haya sesión.
//   - HomeNavigation:  las 5 pestañas de la barra inferior.
//
// Arquitectura del proyecto:
//   screens/  → pantallas
//   widgets/  → piezas reutilizables
//   core/services/ → stores en memoria (ExercisesState, TrainingsState) y
//                    clientes HTTP contra pingpro_back
//   models/   → objetos de datos con fromJson/toJson
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pingpro_front/models/training_model.dart';
import 'package:pingpro_front/screens/pingpro_edit_profile_screen.dart';
import 'package:pingpro_front/screens/pingpro_exercise_detail_screen.dart';
import 'package:pingpro_front/screens/pingpro_login_screen.dart';
import 'package:pingpro_front/screens/pingpro_register_screen.dart';
import 'package:pingpro_front/screens/pingpro_settings_screen.dart';
import 'package:pingpro_front/screens/pingpro_splash_screen.dart';
import 'package:pingpro_front/screens/pingpro_stats_detail_screen.dart';
import 'package:pingpro_front/screens/pingpro_stats_screen.dart';
import 'package:pingpro_front/screens/pingpro_training_detail_screen.dart';
import 'package:pingpro_front/screens/pingpro_welcome_screen.dart';
import 'package:pingpro_front/screens/pingpro_home_screen.dart';
import 'package:pingpro_front/screens/pingpro_exercises_screen.dart';
import 'package:pingpro_front/screens/pingpro_create_screen.dart';
import 'package:pingpro_front/screens/pingpro_trainings_screen.dart';
import 'package:pingpro_front/screens/pingpro_profile_screen.dart';
import 'package:pingpro_front/widgets/custom_bottom_navigation.dart';
import 'package:pingpro_front/widgets/reduce_motion_scope.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/app_licenses.dart';
import 'package:pingpro_front/core/services/app_preferences.dart';
import 'package:pingpro_front/core/services/daily_reminder.dart';
import 'package:pingpro_front/core/services/exercises_state.dart';
import 'package:pingpro_front/core/services/trainings_state.dart';
import 'package:pingpro_front/core/services/session_roles.dart';
import 'package:pingpro_front/core/services/stats_state.dart';
import 'package:pingpro_front/core/services/current_session.dart';

void main() async {
  // ensureInitialized() debe ir primero: dotenv y Firebase necesitan el binding
  // de plataforma listo antes de que exista el árbol de widgets.
  WidgetsFlutterBinding.ensureInitialized();
  registerAppLicenses();
  // Solo vertical, aunque el móvil tenga el giro automático activado: la mesa
  // del editor y el visor 3D están diseñados en vertical. También se fija en
  // AndroidManifest.xml e Info.plist, que valen desde la pantalla de arranque,
  // antes de que Flutter llegue a ejecutarse.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await dotenv.load();          // API_BASE_URL, declarado como asset en pubspec.yaml
  await Firebase.initializeApp();
  // Antes de runApp: la primera pantalla ya tiene que respetar "Reducir
  // animaciones".
  await AppPreferences.instance.load();

  runApp(const MainApp());
  // Tras el primer frame: restore() corre síncrono hasta su primer await y
  // cargar la base de zonas horarias es costoso, así que antes de runApp
  // retrasaría la primera pantalla.
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => unawaited(DailyReminder.instance.restore()),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PingPro',
      theme: ThemeData(scaffoldBackgroundColor: AppColors.background),
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          ReduceMotionScope(preferences: AppPreferences.instance, child: child!),
      // Sin `initialRoute`: con él, Navigator construía la pila ['/', '/welcome']
      // y el onboarding tapaba a AuthWrapper, así que una sesión abierta
      // terminaba igualmente en Welcome. Quien decide al arrancar es AuthWrapper.
      routes: {
        '/welcome': (ctx) => const PingproWelcomeScreen(),
        '/login': (ctx) => const PingproLoginScreen(),
        '/register': (ctx) => const PingproRegisterScreen(),
        '/splash': (ctx) => const PingproSplashScreen(),
        '/home': (ctx) => const HomeNavigation(),
        '/exercises': (ctx) => const PingproExercisesScreen(),
        // Rutas con argumentos: se pasan por pushNamed(arguments: ...) y se
        // desempacan aquí. exerciseDetail recibe un Map porque necesita dos
        // valores (el ejercicio y a qué pantalla volver).
        '/exerciseDetail': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as Map;
          return PingproExerciseDetailScreen(
            exercise: args['exercise'],
            returnRoute: args['returnRoute'],
          );
        },
        '/create': (ctx) => const PingproCreateScreen(),
        '/trainings': (ctx) => const PingproTrainingsScreen(),
        '/trainingDetail': (ctx) {
          final training = ModalRoute.of(ctx)!.settings.arguments as TrainingModel;
          return PingproTrainingDetailScreen(
            training: training
          );
        },
        '/profile': (ctx) => const PingproProfileScreen(),
        '/editProfile': (ctx) => const PingproEditProfileScreen(),
        '/settings': (ctx) => const PingproSettingsScreen(),
        '/stats': (ctx) => const PingproStatsScreen(),
        '/statsDetail': (ctx) => const PingproStatsDetailScreen(),
      },
      home: const AuthWrapper(),
    );
  }
}

/// Portero de la app: escucha el estado de sesión de Firebase y muestra Home o
/// Welcome según corresponda.
///
/// Al ser un Stream y no una comprobación puntual, también reacciona al cerrar
/// sesión: la app vuelve sola a Welcome sin necesidad de navegar a mano.
///
/// Además es el único sitio donde se vacían los stores. Al ser singletons, sus
/// datos sobreviven al cierre de sesión; vaciarlos aquí cubre todas las salidas
/// (logout, el signOut previo al registro, un token revocado) en vez de tener
/// que acordarse en cada una.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _lastUid;

  // Se llama desde el builder del StreamBuilder, así que no puede tocar el
  // árbol en caliente: reset() de los stores ya difiere la notificación.
  void _resetStoresIfUserChanged(String? uid) {
    if (uid == _lastUid) return;
    final signedOut = _lastUid != null && uid == null;
    _lastUid = uid;
    ExercisesState.instance.reset();
    TrainingsState.instance.reset();
    StatsState.instance.reset();
    CurrentSession.instance.reset();
    SessionRoles.instance.reset();
    // Cerrar sesión o eliminar la cuenta apaga el recordatorio. Después del
    // frame: apagarlo avisa a AppPreferences y aquí estamos en mitad de un build.
    if (signedOut) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(DailyReminder.instance.stop()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final user = snapshot.data;
        _resetStoresIfUserChanged(user?.uid);
        if (user != null) {
          return const HomeNavigation();
        }
        return const PingproWelcomeScreen();
      },
    );
  }
}

/// Contenedor de las 5 pestañas principales.
///
/// Usa IndexedStack en vez de cambiar el body: mantiene vivas las cinco
/// pantallas, así que el scroll y el estado de cada pestaña sobreviven al
/// cambiar de tab y no se vuelve a llamar initState (ni a recargar datos).
///
/// El fundido al cambiar de pestaña va sobre el IndexedStack entero: solo se
/// ve la pestaña activa, así que animar el conjunto equivale a animar esa.
class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});
  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    PingproHomeScreen(),
    PingproExercisesScreen(),
    PingproCreateScreen(),
    PingproTrainingsScreen(),
    PingproProfileScreen(),
  ];

  // Arranca completo: la primera pestaña no se funde al entrar a la app.
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _fade,
    curve: Curves.easeOut,
  );

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    if (MediaQuery.of(context).disableAnimations) return;
    _fade.forward(from: 0);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _opacity,
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
