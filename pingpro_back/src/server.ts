/**
 * Punto de entrada del proceso: levanta el servidor HTTP con la app de Express
 * ya configurada en app.ts.
 *
 * Cadena completa de una petición:
 *   server.ts → app.ts → routes/ → middlewares/ → controllers/ → services/
 *   → repositories/ → Firestore
 */
import app from './app';

const PORT = process.env.PORT || 3000;

// Running Port
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
