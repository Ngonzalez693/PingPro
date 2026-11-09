/**
 * Comprobación de la foto de perfil en el borde de la API: el cuerpo tiene que
 * ser un PNG de verdad, no solo traer la cabecera Content-Type de PNG.
 */
import { HTTP_STATUS } from './constants';
import { HttpError } from './httpError';

const PNG_SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

export function assertPng(body: unknown): Buffer {
  const isPng =
    Buffer.isBuffer(body) &&
    body.length > PNG_SIGNATURE.length &&
    body.subarray(0, PNG_SIGNATURE.length).equals(PNG_SIGNATURE);
  if (!isPng) throw new HttpError(HTTP_STATUS.BAD_REQUEST, 'La foto tiene que ser una imagen PNG');
  return body;
}
