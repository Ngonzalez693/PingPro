import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/models/content_scope.dart';
import 'package:pingpro_front/screens/pingpro_create_screen.dart';

void main() {
  Future<void> open(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: screen));
  }

  testWidgets('como pestaña de la barra no tiene flecha ni título de catálogo', (tester) async {
    await open(tester, const PingproCreateScreen());

    expect(find.text('Crear para el catálogo'), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('en modo catálogo lo dice y se puede volver', (tester) async {
    await open(tester, const PingproCreateScreen(scope: ContentScope.catalog));

    expect(find.text('Crear para el catálogo'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('cambiar de pestaña no borra lo escrito en la otra', (tester) async {
    await open(tester, const PingproCreateScreen());

    await tester.enterText(find.widgetWithText(TextField, 'Nombre del ejercicio'), 'Saque corto');
    await tester.tap(find.text('Entrenamientos'));
    await tester.pump();
    // .first: el formulario de entrenamientos, que sigue construido, también
    // tiene un título "Ejercicios"; la pestaña es la primera.
    await tester.tap(find.text('Ejercicios').first);
    await tester.pump();

    expect(find.text('Saque corto'), findsOneWidget);
  });
}
