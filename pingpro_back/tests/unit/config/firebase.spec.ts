// La regla más importante de los tests: nunca conectar con el proyecto real de
// Firebase. config/firebase se carga desde cero en cada caso (isolateModules),
// porque firebase-admin solo permite inicializar la app una vez por registro
// de módulos.
describe('config/firebase', () => {
  const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;

  afterEach(() => {
    process.env.FIRESTORE_EMULATOR_HOST = emulatorHost;
  });

  it('se niega a arrancar en tests si no hay emulador configurado', () => {
    delete process.env.FIRESTORE_EMULATOR_HOST;

    expect(() => {
      jest.isolateModules(() => {
        require('../../../src/config/firebase');
      });
    }).toThrow('Tests must run against the Firebase emulators');
  });

  it('con emulador arranca contra el proyecto demo y sin la clave de servicio', () => {
    jest.isolateModules(() => {
      require('../../../src/config/firebase');
      const { getApp } = require('firebase-admin/app') as typeof import('firebase-admin/app');

      expect(getApp().options.projectId).toBe('demo-pingpro');
      // cert() deja la clave privada en la credencial. Si firebase-admin pone
      // su credencial por defecto (o ninguna), no hay clave: no se usó el .env.
      expect(getApp().options.credential ?? {}).not.toHaveProperty('privateKey');
    });
  });
});
