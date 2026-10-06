// Fila de Configuración: ícono, título y subtítulo opcional.
//
// Una fila tocable lleva flecha y una de solo lectura nada.
// Solo las tocables rebotan al presionar: en una de lectura sería engañoso.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';
import 'package:pingpro_front/widgets/pressable_scale.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      leading: Icon(icon, color: AppColors.textWhite),
      title: Text(title, style: TextStyles.paragraph),
      subtitle: subtitle == null ? null : Text(subtitle!, style: TextStyles.caption),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right, color: AppColors.textGray),
      onTap: onTap,
    );
    return onTap == null ? tile : PressableScale(child: tile);
  }
}
