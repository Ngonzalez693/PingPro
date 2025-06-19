import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final bool obscure;
  const CustomTextField({super.key, required this.hint, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
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
