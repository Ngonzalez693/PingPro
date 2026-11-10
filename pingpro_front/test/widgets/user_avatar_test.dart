import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/widgets/user_avatar.dart';

void main() {
  Future<void> pumpAvatar(
    WidgetTester tester, {
    String? photoUrl,
    VoidCallback? onCameraTap,
    bool busy = false,
  }) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: UserAvatar(photoUrl: photoUrl, radius: 42, onCameraTap: onCameraTap, busy: busy),
        ),
      ),
    ));
  }

  ImageProvider? imageOf(WidgetTester tester) =>
      tester.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundImage;

  testWidgets('sin foto enseña el avatar por defecto', (tester) async {
    await pumpAvatar(tester);

    expect(imageOf(tester), const AssetImage('assets/images/avatar_placeholder.png'));
  });

  testWidgets('con foto la carga de su URL', (tester) async {
    await pumpAvatar(tester, photoUrl: 'https://x/u1/a.png');

    expect(imageOf(tester), const NetworkImage('https://x/u1/a.png'));
  });

  testWidgets('sin callback no hay botón de cámara', (tester) async {
    await pumpAvatar(tester);

    expect(find.byIcon(Icons.photo_camera), findsNothing);
  });

  testWidgets('tocar la cámara avisa una vez', (tester) async {
    var taps = 0;
    await pumpAvatar(tester, onCameraTap: () => taps++);

    await tester.tap(find.byIcon(Icons.photo_camera));

    expect(taps, 1);
  });

  testWidgets('mientras sube enseña el indicador y la cámara no responde', (tester) async {
    var taps = 0;
    await pumpAvatar(tester, onCameraTap: () => taps++, busy: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byIcon(Icons.photo_camera), warnIfMissed: false);
    expect(taps, 0);
  });
}
