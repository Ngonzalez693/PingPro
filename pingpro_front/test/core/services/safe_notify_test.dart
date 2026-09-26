import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/services/safe_notify.dart';

class _Store extends ChangeNotifier with SafeNotify {
  void change() => safeNotify();
}

void main() {
  testWidgets('fuera de un build notifica en el momento', (tester) async {
    final store = _Store();
    var notified = 0;
    store.addListener(() => notified++);

    store.change();

    expect(notified, 1);
  });

  testWidgets('en mitad de un build espera al final del frame en vez de romper', (tester) async {
    final store = _Store();
    var notified = 0;
    store.addListener(() => notified++);

    await tester.pumpWidget(Builder(builder: (context) {
      // Lo que hace una pantalla que llama a load() desde initState.
      store.change();
      return const SizedBox();
    }));

    expect(tester.takeException(), isNull);
    expect(notified, 1);
  });

  test('sin nadie escuchando no hace nada', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    expect(() => _Store().change(), returnsNormally);
  });
}
