/**
 * Versión mínima de Node para arrancar el backend.
 *
 * La impone jose (firebase-admin → jwks-rsa → jose): solo se publica como ESM,
 * y Node carga ESM con require() recién desde la 22.12. Con una 22 anterior el
 * proceso muere al importar firebase-admin con un ERR_REQUIRE_ESM poco claro.
 */
export const MIN_NODE_VERSION = '22.12.0';

const parse = (version: string): number[] =>
  version.replace(/^v/, '').split('.').map((part) => Number(part));

/** Si `version` (formato de process.version, "v22.12.0") cumple el mínimo. */
export const isSupportedNode = (version: string): boolean => {
  const current = parse(version);
  const minimum = parse(MIN_NODE_VERSION);
  for (let i = 0; i < minimum.length; i++) {
    if (current[i] !== minimum[i]) return current[i] > minimum[i];
  }
  return true;
};
