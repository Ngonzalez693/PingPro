import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/profile_name_form.dart';

void main() {
  String? saved;
  var cancels = 0;

  Future<void> pumpForm(WidgetTester tester, {bool saving = false}) async {
    saved = null;
    cancels = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProfileNameForm(
          initialName: 'Nicolás',
          email: 'nico@mail.com',
          saving: saving,
          onSave: (name) => saved = name,
          onCancel: () => cancels++,
        ),
      ),
    ));
  }

  ButtonStyleButton saveButton(WidgetTester tester) => tester.widget<ButtonStyleButton>(
        find.ancestor(of: find.text('Guardar cambios'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)),
      );

  testWidgets('sin cambios no se puede guardar', (tester) async {
    await pumpForm(tester);

    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('con un nombre nuevo guarda el nombre sin espacios de más', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextField), '  Nico G.  ');
    await tester.pump();
    await tester.tap(find.text('Guardar cambios'));

    expect(saved, 'Nico G.');
  });

  testWidgets('un nombre de solo espacios o igual al de antes no cuenta', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Nicolás ');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('Cancelar avisa sin guardar', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextField), 'Otro');
    await tester.pump();
    await tester.tap(find.text('Cancelar'));

    expect(cancels, 1);
    expect(saved, isNull);
  });

  testWidgets('el correo se ve pero no se puede editar', (tester) async {
    await pumpForm(tester);

    expect(find.text('nico@mail.com'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(TextField, 'nico@mail.com'), findsNothing);
  });

  testWidgets('mientras guarda enseña el indicador y no deja tocar nada', (tester) async {
    await pumpForm(tester, saving: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final cancel = tester.widget<ButtonStyleButton>(
      find.ancestor(of: find.text('Cancelar'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)),
    );
    expect(cancel.onPressed, isNull);
    expect(find.text('Guardar cambios'), findsNothing);
  });
}
