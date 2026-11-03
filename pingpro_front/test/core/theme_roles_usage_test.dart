import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Los únicos que pueden usar los colores de rol de AppColors directamente: la
// paleta en sí (de donde sale el modo oscuro) y la tarjeta del visor 3D, que
// es gris en los dos temas. Cualquier otro uso se vería con el color oscuro en
// modo claro.
const _fixed = <String>{
  'lib/core/app_colors.dart',
  'lib/core/pingpro_colors.dart',
  'lib/widgets/exercise_animation_view.dart',
};

final _roleColor = RegExp(r'AppColors\.(?!accent\b)');

void main() {
  test('fuera de la paleta nadie usa colores de rol ni TextStyles', () {
    final offenders = <String>[];
    final files = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/');
      if (_fixed.contains(path)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (_roleColor.hasMatch(lines[i]) || lines[i].contains('TextStyles.')) {
          offenders.add('$path:${i + 1}: ${lines[i].trim()}');
          break;
        }
      }
    }

    expect(offenders, isEmpty);
  });
}
