/**
 * Política de privacidad pública (GET /privacy).
 *
 * La enlaza Configuración en la app y sirve también como la URL de
 * "eliminación de cuenta" que pide la ficha de Google Play: por eso explica
 * cómo borrar la cuenta sin necesidad de tener la app instalada.
 *
 * HTML estático y sin scripts; el único dato variable es el correo de
 * soporte, que se escapa porque sale del .env y termina dentro de atributos.
 */
const escapeHtml = (text: string): string =>
  text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

const STYLE = `
  body { background: #000; color: #fff; font-family: sans-serif; line-height: 1.6;
         max-width: 720px; margin: 0 auto; padding: 24px 16px; }
  h1, h2 { color: #ECFF17; }
  a { color: #ECFF17; }
`;

const BODY = `
  <h1>Política de privacidad de PingPro</h1>
  <p>Última actualización: 5 de octubre de 2026.</p>
  <h2>Qué datos guardamos</h2>
  <p>Tu correo y tu nombre de usuario, los ejercicios y entrenamientos que creas,
  tus favoritos y el historial de ejercicios y entrenamientos que completas.</p>
  <h2>Para qué los usamos</h2>
  <p>Solo para que la app funcione y para mostrarte tus estadísticas. No
  mostramos publicidad. No vendemos tus datos ni los compartimos con terceros,
  salvo con los proveedores que hacen funcionar el servicio (ver abajo).</p>
  <h2>Dónde se guardan</h2>
  <p>La cuenta (correo y contraseña) en Firebase Authentication, de Google. El
  resto, en una base de datos PostgreSQL alojada en Supabase, a la que accede el
  servidor de PingPro, alojado en Hostinger. Estos proveedores solo procesan los
  datos para prestar el servicio.</p>
  <h2>Cuánto tiempo</h2>
  <p>Mientras tengas la cuenta. Al eliminarla se borran todos tus datos.</p>
`;

export const renderPrivacyPage = (supportEmail?: string): string => {
  const email = supportEmail?.trim();
  const link = email ? `<a href="mailto:${escapeHtml(email)}">${escapeHtml(email)}</a>` : '';
  const byMail = link ? `, o pidiéndolo por correo a ${link}` : '';
  const contact = link ? `<h2>Contacto</h2><p>${link}</p>` : '';

  return `<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Política de privacidad · PingPro</title>
  <style>${STYLE}</style>
</head>
<body>
  ${BODY}
  <h2>Cómo eliminar tu cuenta</h2>
  <p>Desde la app, en Configuración → Eliminar cuenta${byMail}.</p>
  ${contact}
</body>
</html>`;
};
