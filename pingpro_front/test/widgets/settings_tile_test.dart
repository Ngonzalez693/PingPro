import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/app_colors.dart';
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

  testWidgets('una fila destructiva pinta ícono y título de rojo', (tester) async {
    await pump(
      tester,
      SettingsTile(icon: Icons.delete_forever, title: 'Eliminar cuenta', destructive: true, onTap: () {}),
    );

    expect(tester.widget<Text>(find.text('Eliminar cuenta')).style?.color, AppColors.danger);
    expect(tester.widget<Icon>(find.byIcon(Icons.delete_forever)).color, AppColors.danger);
  });

  testWidgets('un trailing propio reemplaza a la flecha', (tester) async {
    await pump(
      tester,
      SettingsTile(
        icon: Icons.motion_photos_off_outlined,
        title: 'Reducir animaciones',
        trailing: Switch(value: false, onChanged: (_) {}),
        onTap: () {},
      ),
    );

    expect(find.byType(Switch), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });
}
