// Cuerpo de POST /api/{exercises|trainings}/:id/completed, común a los dos
// servicios. La sesión solo va si hay una: sin ella el backend la guarda como
// "sin sesión".

Map<String, Object> completionBody(bool completed, int? session) => {
  'completed': completed,
  if (session != null) 'session': session,
};
