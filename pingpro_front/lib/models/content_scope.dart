// A dónde va lo que se crea.
//
//   own      → privado de quien lo crea; solo lo ve esa persona.
//   catalog  → el catálogo compartido, visible para todos. Solo un admin puede
//              crear aquí: el backend lo exige con requireRole, y la app solo
//              enseña el acceso a los admins.
enum ContentScope { own, catalog }
