import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/custom_text_field.dart';

bool _obscured(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).obscureText;

Future<void> _pump(WidgetTester tester, {required bool obscure}) => tester.pumpWidget(MaterialApp(
  home: Scaffold(body: CustomTextField(hint: 'Contraseña', obscure: obscure)),
));

void main() {
  testWidgets('una contraseña empieza oculta y el ojo la muestra y la vuelve a ocultar', (tester) async {
    await _pump(tester, obscure: true);
    expect(_obscured(tester), isTrue);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(_obscured(tester), isFalse);

    await tester.tap(find.byTooltip('Ocultar contraseña'));
    await tester.pump();
    expect(_obscured(tester), isTrue);
  });

  testWidgets('un campo normal no tiene ojo', (tester) async {
    await _pump(tester, obscure: false);

    expect(_obscured(tester), isFalse);
    expect(find.byType(IconButton), findsNothing);
  });
}
