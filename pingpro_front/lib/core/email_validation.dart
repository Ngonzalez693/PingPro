// Chequeo de formato de email antes de llamar a Firebase.
//
// Es deliberadamente laxo (algo@algo.algo, sin espacios): solo sirve para dar
// un error claro en el momento. Quien decide si el email es válido de verdad
// es Firebase Auth.
final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

bool isValidEmail(String email) => _emailPattern.hasMatch(email);
