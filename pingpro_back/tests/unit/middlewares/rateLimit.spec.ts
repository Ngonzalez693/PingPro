import express from 'express';
import request from 'supertest';
import { signupLimiter } from '../../../src/middlewares/rateLimit';
import { TRUST_PROXY_HOPS } from '../../../src/utils/constants';

// App mínima en vez de importar src/app.ts: app.ts arrastra config/firebase.ts,
// que falla sin credenciales. Lo que importa es probar el limitador real con el
// mismo `trust proxy` que producción.
const app = express();
app.set('trust proxy', TRUST_PROXY_HOPS);
app.post('/signup', signupLimiter, (_req, res) => {
  res.status(201).json({ success: true });
});

const LIMIT = 20;

// Reproduce el X-Forwarded-For que entrega Hostinger: IPs falsas que mande el
// cliente, su IP real y las N − 1 direcciones de los proxies intermedios. El
// socket de supertest (localhost) hace de último salto.
function viaProxies(clientIp: string, forged: string[] = []): string {
  const proxies = Array.from({ length: TRUST_PROXY_HOPS - 1 }, (_, i) => `10.0.0.${i + 1}`);
  return [...forged, clientIp, ...proxies].join(', ');
}

function signupFrom(clientIp: string, forged: string[] = []) {
  return request(app).post('/signup').set('X-Forwarded-For', viaProxies(clientIp, forged));
}

async function exhaust(clientIp: string) {
  for (let i = 0; i < LIMIT; i++) {
    const res = await signupFrom(clientIp);
    expect(res.status).toBe(201);
  }
}

// Cada test usa IPs propias: el contador en memoria se comparte entre tests.
describe('signupLimiter', () => {
  it('deja pasar 20 registros de una IP y responde 429 al 21.º', async () => {
    await exhaust('203.0.113.1');

    const res = await signupFrom('203.0.113.1');

    expect(res.status).toBe(429);
    expect(res.body).toEqual({
      success: false,
      message: 'Demasiados registros desde esta red. Intenta de nuevo en unos minutos.',
    });
    expect(res.headers['ratelimit']).toBeDefined();
  });

  it('cuenta por cliente: bloquear una IP no bloquea a otra detrás del mismo proxy', async () => {
    await exhaust('203.0.113.2');

    const res = await signupFrom('203.0.113.3');

    expect(res.status).toBe(201);
  });

  it('no se puede esquivar anteponiendo una IP falsa en X-Forwarded-For', async () => {
    await exhaust('203.0.113.4');

    const res = await signupFrom('203.0.113.4', ['198.51.100.7']);

    expect(res.status).toBe(429);
  });
});
