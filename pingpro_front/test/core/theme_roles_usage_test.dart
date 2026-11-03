import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Archivos que ya toman sus colores de los roles del tema. Si uno vuelve a
// usar un color de rol de AppColors o un estilo de TextStyles, en modo claro
// se vería con el color oscuro.
const _migrated = <String>[
  'lib/main.dart',
  'lib/widgets/change_password_dialog.dart',
  'lib/widgets/confirm_action_dialog.dart',
  'lib/widgets/delete_account_dialog.dart',
  'lib/widgets/forgot_password_dialog.dart',
  'lib/widgets/logout_dialog.dart',
  'lib/widgets/stroke_picker_dialog.dart',
  'lib/widgets/exercise_picker_sheet.dart',
  'lib/widgets/content_actions_menu.dart',
  'lib/widgets/exercise_done.dart',
  'lib/widgets/count_bars.dart',
  'lib/widgets/sessions_chart.dart',
  'lib/widgets/statistics_chart.dart',
  'lib/widgets/statistics_secundary_cart.dart',
  'lib/widgets/consistency_card.dart',
  'lib/widgets/exercise_rank_list.dart',
  'lib/widgets/summary_icon.dart',
  'lib/widgets/stroke_arrows_painter.dart',
  'lib/widgets/pingpong_table.dart',
  'lib/widgets/dragged_row_decorator.dart',
  'lib/widgets/create_training_form.dart',
  'lib/widgets/create_exercise_form.dart',
  'lib/widgets/image_option_picker.dart',
  'lib/core/form_styles.dart',
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
