// Encabezado de sección de Configuración ("CUENTA", "ACERCA DE").
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/text_styles.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }
}
