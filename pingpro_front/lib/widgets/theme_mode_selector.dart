// Elección del tema en Configuración: Oscuro (el de siempre), Claro o el del
// teléfono. Escucha a AppPreferences para que la pastilla elegida siga al valor
// guardado, y el cambio se ve al instante en toda la app.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/services/app_preferences.dart';
import 'package:pingpro_front/widgets/labeled_tabs.dart';

class ThemeModeSelector extends StatelessWidget {
  final AppPreferences preferences;

  const ThemeModeSelector({super.key, required this.preferences});

  static const _options = [
    (ThemeMode.dark, 'Oscuro'),
    (ThemeMode.light, 'Claro'),
    (ThemeMode.system, 'Sistema'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tema', style: context.text.paragraph),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: preferences,
            builder: (context, _) => LabeledTabs<ThemeMode>(
              options: _options,
              selected: preferences.themeMode,
              onSelected: preferences.setThemeMode,
            ),
          ),
        ],
      ),
    );
  }
}
