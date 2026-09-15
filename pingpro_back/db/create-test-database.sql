-- Rol y base de datos de los tests de integración, en el PostgreSQL 17 local
-- (puerto 5433). Se lanza una sola vez, como superusuario:
--   psql -U postgres -p 5433 -f db/create-test-database.sql
--
-- La contraseña no es secreta: este rol solo existe en el PC de desarrollo y
-- src/config/postgres.ts impide que los tests usen otra base.
--
-- ENCODING 'UTF8' explícito: en Windows la plantilla por defecto puede ser
-- WIN1252, y los CHECK del esquema llevan tildes ('Técnico', 'Táctico').
CREATE ROLE pingpro_test LOGIN PASSWORD 'pingpro_test';
CREATE DATABASE pingpro_test OWNER pingpro_test ENCODING 'UTF8' TEMPLATE template0;
