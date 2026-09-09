// Paleta única de la app. Ningún widget debe declarar un Color literal:
// todo color sale de aquí para poder cambiar el tema en un solo sitio.
//
// El tema es oscuro: fondo negro con amarillo lima (`primary`) como acento.
import 'dart:ui';

class AppColors {
  static const Color primary = Color(0xFFECFF17);
  static const Color secundary = Color(0xFFFBFFCA);
  static const Color accent = Color(0xFFFF0FCF);

  static const Color background = Color(0xFF000000);
  static const Color widgetBackground = Color(0xFFFBFFCA);
  static const Color widgetBackgroundSelected = Color(0xFFECFF17);
  static const Color widgetGrayBackground = Color(0xFFD9D9D9);
  static const Color tab = Color(0xFF1A1A1A);

  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textBlack = Color(0xFF000000);
  static const Color textGray = Color(0xFF6F6F6F);
}
