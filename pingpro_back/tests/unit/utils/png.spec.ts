import { assertPng } from '../../../src/utils/png';

const SIGNATURE = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

describe('assertPng', () => {
  it('devuelve el mismo buffer si empieza con la firma PNG', () => {
    const png = Buffer.from([...SIGNATURE, 1, 2, 3]);

    expect(assertPng(png)).toBe(png);
  });

  it.each([
    ['vacío', Buffer.alloc(0)],
    ['JPEG', Buffer.from([0xff, 0xd8, 0xff, 0xe0])],
    ['solo media firma', Buffer.from(SIGNATURE.slice(0, 4))],
    ['texto', 'hola'],
    ['objeto (sin cuerpo raw)', {}],
  ])('rechaza con 400 un cuerpo %s', (_name, body) => {
    expect(() => assertPng(body)).toThrow(expect.objectContaining({ status: 400 }));
  });
});
