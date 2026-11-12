// Avatar del usuario: su foto de perfil o, sin foto, el avatar por defecto.
//
// En la pantalla Perfil lleva el botón de cámara para cambiarla; en la pestaña
// Perfil solo se enseña. Si la foto no carga (sin conexión, borrada), se ve el
// avatar por defecto en vez de un hueco.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';

const _placeholder = AssetImage('assets/images/avatar_placeholder.png');

class UserAvatar extends StatefulWidget {
  final String? photoUrl;
  final double radius;
  final VoidCallback? onCameraTap;
  final bool busy;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.radius,
    this.onCameraTap,
    this.busy = false,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _failedUrl;

  // Cada vez que la pantalla lo vuelve a dibujar (al volver, al refrescar) se
  // reintenta la foto: si falló por estar sin conexión, ahora puede cargar.
  // NetworkImage ya saca del caché las cargas fallidas.
  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _failedUrl = null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = widget.photoUrl;
    final showPhoto = url != null && url != _failedUrl;
    final avatar = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(shape: BoxShape.circle, border: surfaceOutline(colors)),
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: colors.card,
        backgroundImage: showPhoto ? NetworkImage(url) : _placeholder,
        onBackgroundImageError: showPhoto ? (_, __) => setState(() => _failedUrl = url) : null,
      ),
    );
    final onCameraTap = widget.onCameraTap;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (widget.busy)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: colors.page.withValues(alpha: 0.6)),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        if (onCameraTap != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: _CameraBadge(onTap: widget.busy ? null : onCameraTap),
          ),
      ],
    );
  }
}

class _CameraBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const _CameraBadge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.brandFill,
      shape: CircleBorder(side: BorderSide(color: colors.page, width: 2)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(Icons.photo_camera, size: 18, color: colors.onBrandFill),
        ),
      ),
    );
  }
}
