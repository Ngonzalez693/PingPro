import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/app_preferences.dart';
import 'package:pingpro_front/widgets/reduce_motion_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<AppPreferences> loaded({required bool reduceMotion}) async {
    SharedPreferences.setMockInitialValues({'reduceMotion': reduceMotion});
    final prefs = AppPreferences.forTesting();
    await prefs.load();
    return prefs;
  }

  // Devuelve una función que lee lo que ve una pantalla cualquiera de la app.
  Future<bool Function()> pumpApp(WidgetTester tester, AppPreferences prefs) async {
    late bool seen;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => ReduceMotionScope(preferences: prefs, child: child!),
      home: Builder(builder: (context) {
        seen = MediaQuery.disableAnimationsOf(context);
        return const SizedBox();
      }),
    ));
    return () => seen;
  }

  testWidgets('sin sistema ni preferencia, las animaciones siguen', (tester) async {
    final seen = await pumpApp(tester, await loaded(reduceMotion: false));

    expect(seen(), isFalse);
  });

  testWidgets('la preferencia las apaga aunque el sistema no', (tester) async {
    final seen = await pumpApp(tester, await loaded(reduceMotion: true));

    expect(seen(), isTrue);
  });

  testWidgets('el ajuste del sistema las apaga aunque la preferencia no', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final seen = await pumpApp(tester, await loaded(reduceMotion: false));

    expect(seen(), isTrue);
  });

  testWidgets('cambiar la preferencia se nota en vivo', (tester) async {
    final prefs = await loaded(reduceMotion: false);
    final seen = await pumpApp(tester, prefs);

    await prefs.setReduceMotion(true);
    await tester.pump();

    expect(seen(), isTrue);
  });
}
