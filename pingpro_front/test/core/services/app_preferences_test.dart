import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<AppPreferences> loaded(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    final prefs = AppPreferences.forTesting();
    await prefs.load();
    return prefs;
  }

  test('por defecto no reduce animaciones', () async {
    final prefs = await loaded({});

    expect(prefs.reduceMotion, isFalse);
  });

  test('carga lo guardado en el teléfono', () async {
    final prefs = await loaded({'reduceMotion': true});

    expect(prefs.reduceMotion, isTrue);
  });

  test('cambiarla avisa al instante y queda guardada para el próximo arranque', () async {
    final prefs = await loaded({});
    var notified = 0;
    prefs.addListener(() => notified++);

    await prefs.setReduceMotion(true);

    expect(prefs.reduceMotion, isTrue);
    expect(notified, 1);
    final nextLaunch = AppPreferences.forTesting();
    await nextLaunch.load();
    expect(nextLaunch.reduceMotion, isTrue);
  });

  test('poner el mismo valor no avisa', () async {
    final prefs = await loaded({'reduceMotion': true});
    var notified = 0;
    prefs.addListener(() => notified++);

    await prefs.setReduceMotion(true);

    expect(notified, 0);
  });
}
