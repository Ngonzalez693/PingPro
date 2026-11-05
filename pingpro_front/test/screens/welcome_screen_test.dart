import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/screens/pingpro_welcome_screen.dart';

class _Routes extends NavigatorObserver {
  final names = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => names.add(route.settings.name);
}

void main() {
  // El splash va oscuro aunque la app esté en claro porque la ruta '/splash'
  // de main.dart lo envuelve en AlwaysDark. Abrirlo con una ruta propia se
  // saltaba ese envoltorio y lo mostraba con el tema de la app.
  testWidgets('al terminar la bienvenida abre la ruta /splash', (tester) async {
    final routes = _Routes();
    await tester.pumpWidget(MaterialApp(
      home: const PingproWelcomeScreen(),
      navigatorObservers: [routes],
      routes: {'/splash': (_) => const Scaffold(), '/login': (_) => const Scaffold()},
    ));
    routes.names.clear();

    for (final label in ['Siguiente', 'Siguiente', 'Empecemos']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    expect(routes.names, ['/splash']);
  });
}
