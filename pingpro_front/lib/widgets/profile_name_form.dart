// Edición del nombre en el perfil. "Guardar cambios" solo se enciende con un
// nombre nuevo de verdad: sin cambios, o con solo espacios, no hay nada que
// mandar al backend. El correo se enseña al lado pero no se edita.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';

class ProfileNameForm extends StatefulWidget {
  final String initialName;
  final String email;
  final bool saving;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  const ProfileNameForm({
    super.key,
    required this.initialName,
    required this.email,
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ProfileNameForm> createState() => _ProfileNameFormState();
}

class _ProfileNameFormState extends State<ProfileNameForm> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName);

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSave {
    final name = _name.text.trim();
    return !widget.saving && name.isNotEmpty && name != widget.initialName.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(context, 'Nombre'),
        TextField(
          controller: _name,
          autofocus: true,
          enabled: !widget.saving,
          textCapitalization: TextCapitalization.words,
          style: context.text.paragraphBlack,
          decoration: _nameDecoration(context),
        ),
        const SizedBox(height: 12),
        _label(context, 'Correo'),
        _ReadOnlyField(value: widget.email),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _cancelButton(context)),
            const SizedBox(width: 12),
            Expanded(child: _saveButton(context)),
          ],
        ),
      ],
    );
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(text, style: context.text.caption.copyWith(fontSize: 12)),
    );
  }

  // Con el foco el borde pasa al color de acento, como pide el diseño; sin él,
  // el contorno suave de claro (o nada en oscuro).
  InputDecoration _nameDecoration(BuildContext context) {
    final colors = context.colors;
    final idle = outlinedFieldBorder(colors, 12);
    return InputDecoration(
      filled: true,
      fillColor: colors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: idle,
      enabledBorder: idle,
      disabledBorder: idle,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.brand, width: 2),
      ),
    );
  }

  Widget _cancelButton(BuildContext context) {
    final colors = context.colors;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colors.panel,
        disabledBackgroundColor: colors.panel,
        side: surfaceOutlineSide(colors),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: widget.saving ? null : widget.onCancel,
      child: Text(
        'Cancelar',
        style: context.text.paragraph.copyWith(color: widget.saving ? colors.muted : colors.onPage),
      ),
    );
  }

  // Apagado se ve como el de Cancelar con el texto gris: el gris propio de
  // Material para los botones deshabilitados no se distingue del fondo negro.
  Widget _saveButton(BuildContext context) {
    final colors = context.colors;
    final enabled = _canSave;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colors.brandFill,
        disabledBackgroundColor: colors.panel,
        side: enabled ? null : surfaceOutlineSide(colors),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: enabled ? () => widget.onSave(_name.text.trim()) : null,
      child: widget.saving
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPage),
            )
          : Text(
              'Guardar cambios',
              style: context.text.buttons.copyWith(color: enabled ? colors.onBrandFill : colors.muted),
            ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String value;

  const _ReadOnlyField({required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(12),
        border: surfaceOutline(colors),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(value, style: context.text.paragraph.copyWith(color: colors.muted), overflow: TextOverflow.ellipsis),
          ),
          Icon(Icons.lock_outline, size: 20, color: colors.muted),
        ],
      ),
    );
  }
}
