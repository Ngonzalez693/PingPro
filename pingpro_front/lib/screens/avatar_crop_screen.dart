// Mover y ajustar la foto de perfil dentro de un círculo antes de subirla.
//
// Lo que se recorta es el cuadrado del círculo: un RepaintBoundary de ese
// tamaño con la foto dentro de un InteractiveViewer. La foto se ve también
// fuera del círculo (oscurecida) para saber qué queda fuera, pero eso no entra
// en la imagen. "Usar foto" devuelve un PNG de avatarPixels × avatarPixels.
//
// Va siempre en oscuro, como un visor de fotos, en los dos temas.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pingpro_front/core/app_theme.dart';
import 'package:pingpro_front/core/avatar_crop.dart';
import 'package:pingpro_front/widgets/always_dark.dart';

class AvatarCropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const AvatarCropScreen({super.key, required this.imageBytes});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final _boundary = GlobalKey();
  final _transform = TransformationController();
  Size? _imageSize;
  double? _diameter;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _readImageSize();
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Future<void> _readImageSize() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    final size = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    frame.image.dispose();
    codec.dispose();
    if (mounted) setState(() => _imageSize = size);
  }

  // Empieza con la foto centrada y cubriendo el círculo justo.
  void _fitImage(Size image, double diameter) {
    if (_diameter == diameter) return;
    _diameter = diameter;
    final scale = coverScale(image, diameter);
    final dx = (diameter - image.width * scale) / 2;
    final dy = (diameter - image.height * scale) / 2;
    _transform.value =
        Matrix4.identity()
          ..translate(dx, dy)
          ..scale(scale);
  }

  Future<void> _useImage() async {
    final diameter = _diameter;
    if (_saving || diameter == null) return;
    setState(() => _saving = true);
    final boundary = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: avatarPixels / diameter);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (!mounted) return;
    Navigator.pop(context, bytes!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return AlwaysDark(
      child: Builder(
        builder:
            (context) => Scaffold(
              backgroundColor: context.colors.page,
              body: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text('Mueve y ajusta', style: context.text.caption),
                    Expanded(child: _buildCropArea(context)),
                    _buildButtons(context),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildCropArea(BuildContext context) {
    final imageSize = _imageSize;
    if (imageSize == null) return const Center(child: CircularProgressIndicator());
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = constraints.biggest.shortestSide - 48;
        _fitImage(imageSize, diameter);
        final cover = coverScale(imageSize, diameter);
        // La foto se ve fuera del círculo (oscurecida), pero con zoom no puede
        // salirse de esta zona y pintarse sobre la indicación o la barra.
        return ClipRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: diameter,
                child: RepaintBoundary(
                  key: _boundary,
                  child: InteractiveViewer(
                    transformationController: _transform,
                    constrained: false,
                    clipBehavior: Clip.none,
                    minScale: cover,
                    maxScale: cover * 5,
                    child: Image.memory(
                      widget.imageBytes,
                      width: imageSize.width,
                      height: imageSize.height,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  size: constraints.biggest,
                  painter: _CircleMaskPainter(diameter: diameter, ring: context.colors.onPage),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButtons(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: colors.panel,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: shape,
              ),
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: Text('Cancelar', style: context.text.paragraph),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: colors.brandFill,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: shape,
              ),
              onPressed: _imageSize == null || _saving ? null : _useImage,
              child: Text('Usar foto', style: context.text.buttons),
            ),
          ),
        ],
      ),
    );
  }
}

// Oscurece todo menos el círculo y le pone un borde.
class _CircleMaskPainter extends CustomPainter {
  final double diameter;
  final Color ring;

  const _CircleMaskPainter({required this.diameter, required this.ring});

  @override
  void paint(Canvas canvas, Size size) {
    final circle = Rect.fromCircle(center: size.center(Offset.zero), radius: diameter / 2);
    final mask =
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addOval(circle);
    canvas.drawPath(mask, Paint()..color = const Color(0xA6000000));
    canvas.drawOval(
      circle,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CircleMaskPainter old) => old.diameter != diameter || old.ring != ring;
}
