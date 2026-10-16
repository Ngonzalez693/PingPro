// Campo de texto con el estilo oscuro de la app. Se usa en login y registro.
//
// Con `obscure` es un campo de contraseña: empieza oculta y el ojo de la
// derecha la muestra o la vuelve a ocultar, para poder revisar lo escrito.
//
// El color de fondo (0xFF313131) está escrito a mano en vez de salir de
// AppColors: sería el único caso del proyecto y convendría moverlo allí.
import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String hint;
  final bool obscure;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.hint,
    this.obscure = false,
    this.controller,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _hidden,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF313131),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        suffixIcon: widget.obscure ? _buildToggle() : null,
      ),
    );
  }

  Widget _buildToggle() {
    return IconButton(
      icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
      tooltip: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
      onPressed: () => setState(() => _hidden = !_hidden),
    );
  }
}
