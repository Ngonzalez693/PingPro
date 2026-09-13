// Todos los tests corren contra los emuladores de Firebase, nunca contra el
// proyecto real. Se fija aquí, antes de que cualquier test importe
// src/config/firebase: dotenv no sobrescribe variables que ya existen, así que
// el .env de producción no puede colarse.
//
// Un proyecto "demo-" es un proyecto que Firebase garantiza que nunca llega a
// la nube. Si un test unitario hace por error una llamada real, va a 127.0.0.1
// y falla en vez de escribir datos de verdad.
process.env.FIREBASE_PROJECT_ID = 'demo-pingpro';
// 8085 y no el 8080 por defecto: en Windows el 8080 lo suele ocupar el sistema
// (HTTP.sys). Tiene que coincidir con firebase.json.
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8085';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
