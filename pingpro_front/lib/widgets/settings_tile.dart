// Fila de Configuración: ícono, título y subtítulo opcional.
//
// Sin `trailing`, una fila tocable lleva flecha y una de solo lectura nada.
// Solo las tocables rebotan al presionar: en una de lectura sería engañoso.
// `destructive` la pinta de rojo: acciones que no se deshacen.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/widgets/pressable_scale.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? context.colors.danger : context.colors.onPage;
    final tile = ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: context.text.paragraph.copyWith(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: context.text.caption),
      trailing: trailing ?? (onTap == null ? null : Icon(Icons.chevron_right, color: context.colors.muted)),
      onTap: onTap,
    );
    return onTap == null ? tile : PressableScale(child: tile);
  }
}
