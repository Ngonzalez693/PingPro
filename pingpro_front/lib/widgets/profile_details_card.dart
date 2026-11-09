// Datos de la cuenta en el perfil: el nombre, que se puede cambiar, y el
// correo, que es el de la cuenta y solo se muestra.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';

class ProfileDetailsCard extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onEditName;

  const ProfileDetailsCard({
    super.key,
    required this.name,
    required this.email,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(14),
        border: surfaceOutline(colors),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            _DetailRow(
              icon: Icons.person_outline,
              label: 'Nombre',
              value: name,
              trailing: Icon(Icons.edit, size: 20, color: colors.brand),
              onTap: onEditName,
            ),
            Divider(height: 1, indent: 16, endIndent: 16, color: colors.muted.withValues(alpha: 0.3)),
            _DetailRow(
              icon: Icons.mail_outline,
              label: 'Correo',
              value: email,
              trailing: Icon(Icons.lock_outline, size: 20, color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget trailing;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: context.colors.onPage),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.text.caption.copyWith(fontSize: 12)),
                  Text(value, style: context.text.paragraph, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
