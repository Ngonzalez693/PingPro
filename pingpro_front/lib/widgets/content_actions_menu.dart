// Menú ⋮ de la cabecera del detalle de un ejercicio o un entrenamiento.
//
// Quién lo ve lo decide la pantalla (canManage en session_roles.dart); aquí
// solo están las dos opciones.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_colors.dart';
import 'package:pingpro_front/core/text_styles.dart';

enum _ContentAction { edit, delete }

class ContentActionsMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ContentActionsMenu({super.key, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ContentAction>(
      icon: const Icon(Icons.more_vert, color: AppColors.textWhite),
      tooltip: 'Más opciones',
      color: AppColors.widgetBackground,
      onSelected: (action) => action == _ContentAction.edit ? onEdit() : onDelete(),
      itemBuilder: (_) => const [
        PopupMenuItem(value: _ContentAction.edit, child: Text('Editar', style: TextStyles.paragraphBlack)),
        PopupMenuItem(value: _ContentAction.delete, child: Text('Eliminar', style: TextStyles.paragraphBlack)),
      ],
    );
  }
}
