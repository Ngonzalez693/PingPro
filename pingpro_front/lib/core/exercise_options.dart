// Opciones fijas del formulario para crear un ejercicio.

/// Categorías de ejercicio. Tienen que coincidir con EXERCISE_CATEGORIES de
/// pingpro_back/src/utils/constants.ts y con el CHECK de la tabla exercises:
/// cualquier otro valor lo rechaza el backend.
const exerciseCategories = ['Footwork', 'Técnico', 'Táctico', 'Estrategia'];

/// Imágenes que puede elegir un ejercicio creado por el usuario. Son assets de
/// la app, no fotos subidas: el campo `image` del backend guarda la ruta.
const exerciseImages = [
  'assets/images/exercise_1.jpg',
  'assets/images/exercise_2.jpg',
  'assets/images/exercise_3.jpg',
];
