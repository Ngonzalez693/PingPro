import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Archivos que ya toman sus colores de los roles del tema. Si uno vuelve a
// usar un color de rol de AppColors o un estilo de TextStyles, en modo claro
// se vería con el color oscuro.
const _migrated = <String>[
  'lib/main.dart',
];

final _roleColor = RegExp(r'AppColors\.(?!accent\b)');

void main() {
  test('los archivos migrados no usan colores de rol ni TextStyles', () {
    final offenders = <String>[];
    for (final path in _migrated) {
      final lines = File(path).readAsLinesSync();
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
