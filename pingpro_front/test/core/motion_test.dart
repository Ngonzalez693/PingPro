import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingpro_front/core/motion.dart';

void main() {
  const normal = Duration(milliseconds: 300);

  Future<Duration> durationWith(WidgetTester tester, {required bool disableAnimations}) async {
    late Duration result;
    await tester.pumpWidget(MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Builder(builder: (context) {
        result = motionDuration(context, normal);
        return const SizedBox();
      }),
    ));
    return result;
  }

  testWidgets('con animaciones usa la duración normal', (tester) async {
    expect(await durationWith(tester, disableAnimations: false), normal);
  });

  testWidgets('con animaciones reducidas el cambio es instantáneo', (tester) async {
    expect(await durationWith(tester, disableAnimations: true), Duration.zero);
  });
}
