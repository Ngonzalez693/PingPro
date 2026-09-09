// Campo de texto con el estilo oscuro de la app. Se usa en login y registro.
//
// El color de fondo (0xFF313131) está escrito a mano en vez de salir de
// AppColors: sería el único caso del proyecto y convendría moverlo allí.
// custom_text_field.dart
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final TextEditingController? controller;  // Agrega este campo

  const CustomTextField({
    super.key,
    required this.hint,
    this.obscure = false,
    this.controller,  // Inclúyelo en el constructor
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,  // Conéctalo aquí
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF313131),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }
}
