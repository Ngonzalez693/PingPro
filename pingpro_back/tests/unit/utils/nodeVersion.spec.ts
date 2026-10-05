import { isSupportedNode, MIN_NODE_VERSION } from '../../../src/utils/nodeVersion';

describe('isSupportedNode', () => {
  it('acepta exactamente el mínimo', () => {
    expect(isSupportedNode('v22.12.0')).toBe(true);
  });

  it('acepta versiones posteriores de la 22 y mayores nuevas', () => {
    expect(isSupportedNode('v22.12.1')).toBe(true);
    expect(isSupportedNode('v22.20.0')).toBe(true);
    expect(isSupportedNode('v24.0.0')).toBe(true);
  });

  it('rechaza las 22 anteriores a la 22.12', () => {
    expect(isSupportedNode('v22.11.9')).toBe(false);
    expect(isSupportedNode('v22.2.0')).toBe(false);
  });

  it('rechaza mayores viejas', () => {
    expect(isSupportedNode('v20.19.0')).toBe(false);
    expect(isSupportedNode('v18.20.4')).toBe(false);
  });

  it('el mínimo es el que exige jose', () => {
    expect(MIN_NODE_VERSION).toBe('22.12.0');
  });
});
