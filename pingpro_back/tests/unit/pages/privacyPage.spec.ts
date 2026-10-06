import { renderPrivacyPage } from '../../../src/pages/privacyPage';

describe('renderPrivacyPage', () => {
  it('incluye el correo de contacto como enlace mailto', () => {
    const html = renderPrivacyPage('pingproteam@gmail.com');

    expect(html).toContain('href="mailto:pingproteam@gmail.com"');
  });

  it('sin correo no muestra ningún enlace mailto', () => {
    expect(renderPrivacyPage()).not.toContain('mailto:');
    expect(renderPrivacyPage('   ')).not.toContain('mailto:');
  });

  it('explica cómo eliminar la cuenta desde la app', () => {
    expect(renderPrivacyPage()).toContain('Configuración → Eliminar cuenta');
  });

  it('escapa el correo para que no inyecte HTML', () => {
    const html = renderPrivacyPage('<script>@x.com');

    expect(html).not.toContain('<script>');
    expect(html).toContain('&lt;script&gt;@x.com');
  });
});
