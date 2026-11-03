// Aspecto de una fila mientras se arrastra en una lista reordenable.
//
// ReorderableListView pinta la fila arrastrada en una capa aparte y, por
// defecto, con fondo claro: el texto blanco de la fila casi no se veía. Cada
// lista construye su fila en versión "arrastrada" (texto e iconos negros) y
// aquí se le pone el fondo del color secundario.
//
// La fila se reconstruye en vez de cambiar colores por tema porque la capa del
// arrastre copia los temas de la lista, y esos ganarían al de este fondo.
import 'package:flutter/material.dart';
import 'package:pingpro_front/core/app_theme.dart';

/// Color del texto y los iconos de una fila, arrastrada o no.
Color rowForeground(BuildContext context, {required bool dragging}) =>
    dragging ? context.colors.onCard : context.colors.onPage;

/// Fondo de la fila arrastrada.
Widget draggedRowBackground(BuildContext context, Widget row) {
  return Material(
    color: context.colors.softFill,
    elevation: 4,
    borderRadius: BorderRadius.circular(8),
    child: row,
  );
}
