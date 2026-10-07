import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/settings_switch_tile.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget tile) {
    return tester.pumpWidget(MaterialApp(home: Scaffold(body: tile)));
  }

  testWidgets('tocar la fila pide el valor contrario', (tester) async {
    bool? requested;
    await pump(
      tester,
      SettingsSwitchTile(
        icon: Icons.notifications_outlined,
        title: 'Recordatorio diario',
        value: false,
        onChanged: (value) => requested = value,
      ),
    );

    await tester.tap(find.text('Recordatorio diario'));
    await tester.pumpAndSettle();

    expect(requested, isTrue);
  });

  testWidgets('fila y switch son un solo nodo que anuncia el estado', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      SettingsSwitchTile(
        icon: Icons.motion_photos_off_outlined,
        title: 'Reducir animaciones',
        subtitle: 'Desactiva las transiciones',
        value: false,
        onChanged: (_) {},
      ),
    );

    expect(
      tester.getSemantics(find.byType(MergeSemantics)),
      matchesSemantics(
        label: 'Reducir animaciones\nDesactiva las transiciones',
        hasToggledState: true,
        isToggled: false,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });
}
