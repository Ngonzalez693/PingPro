/**
 * GET /privacy — pública y fuera de /api: la abre el navegador desde la app y
 * la ficha de Play, sin token. El correo se lee en cada petición para que un
 * cambio en el .env no necesite recompilar.
 */
import { Router } from 'express';
import { renderPrivacyPage } from '../pages/privacyPage';

const router = Router();

router.get('/', (_req, res) => {
  res.type('html').send(renderPrivacyPage(process.env.SUPPORT_EMAIL));
});

export default router;
