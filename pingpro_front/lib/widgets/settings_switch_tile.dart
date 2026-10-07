// Fila de Configuración con interruptor: tocar la fila o el switch lo cambia.
//
// MergeSemantics la vuelve un solo nodo, como SwitchListTile: el lector de
// pantalla anuncia el estado (activado o no) y no deja una segunda parada de
// foco para el mismo control.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/widgets/settings_tile.dart';

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: SettingsTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        onTap: () => onChanged(!value),
      ),
    );
  }
}
