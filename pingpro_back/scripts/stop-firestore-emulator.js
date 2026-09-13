// @ts-check
/**
 * Para el emulador de Firestore que dejó colgado la ejecución anterior de
 * `npm run test:integration`. npm lo lanza solo, como `pretest:integration`.
 *
 * Por qué hace falta: firebase-tools arranca el emulador con `detached: true`
 * y lo para con SIGINT. En Windows esa señal no cierra el proceso Java, así
 * que se queda escuchando en el puerto y la siguiente ejecución falla con
 * "port taken". En Linux y macOS SIGINT sí lo cierra, así que allí no se hace
 * nada.
 *
 * Solo para un proceso si su línea de comandos es la del emulador de
 * Firestore: cualquier otra cosa en el puerto se deja en paz.
 */
const { execFileSync } = require('node:child_process');
const { readFileSync } = require('node:fs');
const path = require('node:path');

const EMULATOR_MARKER = 'cloud-firestore-emulator';

/** @returns {number} */
function firestorePort() {
  const configPath = path.join(__dirname, '..', 'firebase.json');
  const config = JSON.parse(readFileSync(configPath, 'utf8'));
  const port = config?.emulators?.firestore?.port;
  if (!Number.isInteger(port)) {
    throw new Error(`emulators.firestore.port is missing in ${configPath}`);
  }
  return port;
}

/**
 * Procesos que escuchan en el puerto, con su línea de comandos.
 * @param {number} port
 * @returns {Array<{ pid: number, commandLine: string }>}
 */
function listenersOn(port) {
  // Sin nada escuchando, Get-NetTCPConnection cuenta como fallido y PowerShell
  // sale con código 1 aunque se silencie el error: de ahí los `exit 0`.
  const script = [
    `$c = Get-NetTCPConnection -LocalPort ${port} -State Listen -ErrorAction SilentlyContinue`,
    'if (-not $c) { exit 0 }',
    '$c | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object {',
    '  $p = Get-CimInstance Win32_Process -Filter "ProcessId = $_"',
    '  [pscustomobject]@{ pid = [int]$_; commandLine = [string]$p.CommandLine }',
    '} | ConvertTo-Json -Compress',
    'exit 0',
  ].join('\n');
  const out = execFileSync('powershell', ['-NoProfile', '-NonInteractive', '-Command', script], {
    encoding: 'utf8',
  }).trim();
  if (!out) return [];
  const parsed = JSON.parse(out);
  // ConvertTo-Json devuelve un objeto si hay un solo proceso y un array si hay varios.
  return Array.isArray(parsed) ? parsed : [parsed];
}

/** @param {number} ms */
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * El puerto tarda un momento en liberarse después de parar el proceso.
 * @param {number} port
 */
async function waitUntilFree(port) {
  for (let attempt = 0; attempt < 20; attempt++) {
    if (listenersOn(port).length === 0) return;
    await sleep(250);
  }
  throw new Error(`port ${port} is still in use after stopping the emulator`);
}

async function main() {
  const port = firestorePort();

  if (process.platform !== 'win32') {
    console.log(`[pretest] ${process.platform}: the emulator stops on its own, nothing to do`);
    return;
  }

  const listeners = listenersOn(port);
  if (listeners.length === 0) {
    console.log(`[pretest] Port ${port} is free`);
    return;
  }

  let stopped = 0;
  for (const { pid, commandLine } of listeners) {
    if (!commandLine.includes(EMULATOR_MARKER)) {
      console.warn(`[pretest] Port ${port} is used by another program (pid ${pid}), leaving it alone: ${commandLine}`);
      continue;
    }
    // En Windows process.kill termina el proceso de forma inmediata.
    process.kill(pid);
    stopped++;
    console.log(`[pretest] Stopped leftover Firestore emulator (pid ${pid})`);
  }

  if (stopped > 0) await waitUntilFree(port);
}

main().catch((err) => {
  console.error(`[pretest] Could not clean up the Firestore emulator: ${err.message}`);
  process.exit(1);
});
