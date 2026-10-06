import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/settings_tile.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget tile) {
    return tester.pumpWidget(MaterialApp(home: Scaffold(body: tile)));
  }

  testWidgets('muestra título y subtítulo', (tester) async {
    await pump(tester, const SettingsTile(icon: Icons.email, title: 'Correo', subtitle: 'a@b.c'));

    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('a@b.c'), findsOneWidget);
  });

  testWidgets('una fila tocable avisa y lleva flecha', (tester) async {
    var taps = 0;
    await pump(tester, SettingsTile(icon: Icons.lock, title: 'Cambiar contraseña', onTap: () => taps++));

    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('una fila de solo lectura no lleva flecha', (tester) async {
    await pump(tester, const SettingsTile(icon: Icons.info, title: 'Versión', subtitle: '0.1.0'));

    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });
}
