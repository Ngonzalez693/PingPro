import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/exercise_options.dart';
import 'package:pingpro_front/widgets/create_exercise_form.dart';

// El formulario hasta que abre el editor. La vista previa no se prueba aquí:
// carga el catálogo de modelos 3D por HTTP, y eso se comprueba en el móvil.
void main() {
  Future<void> openForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CreateExerciseForm())));
  }

  // ElevatedButton.icon crea una subclase privada, así que find.byType no la
  // encuentra: se busca por la clase base, que es la que tiene onPressed.
  ButtonStyleButton continueButton(WidgetTester tester) => tester.widget<ButtonStyleButton>(
        find.ancestor(of: find.text('Siguiente'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)),
      );

  bool isSelected(WidgetTester tester, String label) =>
      tester.getSemantics(find.bySemanticsLabel(label)).hasFlag(SemanticsFlag.isSelected);

  testWidgets('sin nombre no se puede seguir', (tester) async {
    await openForm(tester);

    expect(continueButton(tester).onPressed, isNull);
  });

  testWidgets('un nombre de solo espacios tampoco cuenta', (tester) async {
    await openForm(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Nombre del ejercicio'), '   ');
    await tester.pump();

    expect(continueButton(tester).onPressed, isNull);
  });

  testWidgets('con nombre, "Siguiente" abre el editor de secuencias', (tester) async {
    await openForm(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Nombre del ejercicio'), 'Saque corto');
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    expect(find.text('Secuencia'), findsOneWidget);
  });

  testWidgets('al volver del editor no se abre el teclado', (tester) async {
    await openForm(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Nombre del ejercicio'), 'Saque corto');
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back)); // la flecha propia del editor
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('la primera imagen viene elegida y se puede cambiar', (tester) async {
    final handle = tester.ensureSemantics();
    await openForm(tester);

    expect(isSelected(tester, 'Imagen 1'), isTrue);
    expect(isSelected(tester, 'Imagen 3'), isFalse);

    await tester.tap(find.byKey(ValueKey(exerciseImages[2])));
    await tester.pump();

    expect(isSelected(tester, 'Imagen 1'), isFalse);
    expect(isSelected(tester, 'Imagen 3'), isTrue);
    handle.dispose();
  });

  testWidgets('ofrece exactamente las categorías que acepta el backend', (tester) async {
    await openForm(tester);

    await tester.tap(find.text(exerciseCategories.first));
    await tester.pumpAndSettle();

    for (final category in exerciseCategories) {
      expect(find.text(category), findsWidgets);
    }
  });
}
