// Opciones fijas del formulario para crear un entrenamiento.

/// Categorías de entrenamiento. Tienen que coincidir con TRAINING_CATEGORIES de
/// pingpro_back/src/utils/constants.ts y con el CHECK de la tabla trainings:
/// cualquier otro valor lo rechaza el backend.
const trainingCategories = ['Grado', 'Objetivo', 'Momento', 'Estilo', 'Estructura'];

/// Imágenes que puede elegir un entrenamiento creado por el usuario. Son assets
/// de la app: el campo `image` del backend guarda la ruta.
const trainingImages = [
  'assets/images/training_1.jpg',
  'assets/images/training_2.jpg',
  'assets/images/training_3.jpg',
];
