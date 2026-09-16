-- Base de datos de desarrollo local, para el ensayo del corte: se carga en
-- ella el Firestore real y se recorre la app contra el backend local.
-- Se lanza una sola vez, como superusuario:
--   psql -U postgres -p 5433 -f db/create-dev-database.sql
--
-- La contraseña no es secreta: este rol solo existe en el PC de desarrollo.
-- ENCODING 'UTF8' explícito, como en la base de test: en Windows la plantilla
-- por defecto puede ser WIN1252 y los CHECK del esquema llevan tildes.
CREATE ROLE pingpro_dev LOGIN PASSWORD 'pingpro_dev';
CREATE DATABASE pingpro_dev OWNER pingpro_dev ENCODING 'UTF8' TEMPLATE template0;
