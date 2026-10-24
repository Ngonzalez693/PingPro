// Visor 3D de un ejercicio: reproduce la secuencia de golpes como un vídeo
// continuo de una persona real.
//
// - Sin pausas: el golpe siguiente arranca BLEND segundos antes de que acabe
//   el actual y los dos se funden (crossfade).
// - Encadenado como en un peloteo: cada golpe empieza en el suelo donde
//   terminó el anterior. El plan (lib/core/viewer/chain_plan.dart) trae cuánto
//   hay que desplazar cada clip; al repetir el ejercicio se vuelve al inicio.
// - La posición en el suelo (x, z del hueso root.x) la pone el visor y no los
//   clips: mientras dos clips se funden, se mezclan sus posiciones ya
//   desplazadas con los mismos pesos que la pose. Si se desplazara el modelo
//   entero al cambiar de clip, el que se está yendo daría un salto.
// - Los pesos de la mezcla los lleva el visor (weightOf) y no crossFadeTo de
//   three.js: este hace bajar al clip que se va siempre desde 1, y si se salta
//   de paso a mitad de una mezcla, la pose y el suelo darían un tirón.
// - Cámara fija, encuadrada una vez con la zona del suelo de una pasada.
//
// Mensajes a la app por el canal PingPro (ver lib/core/viewer/viewer_bridge.dart).
import * as THREE from 'three';
import { GLTFLoader } from './GLTFLoader.js';
import { OrbitControls } from './OrbitControls.js';

const BLEND = 0.25;
const ROOT_BONE = 'root.x';
// Ángulos de cámara del visor anterior: de frente y algo desde arriba.
const CAMERA_THETA = 0;
const CAMERA_PHI = THREE.MathUtils.degToRad(70);
const CAMERA_FOV = 35;
const FRAME_MARGIN = 1.15;
const MIN_ZOOM = 0.3;
const MAX_ZOOM = 2.5;

const send = (msg) => window.PingPro?.postMessage(JSON.stringify(msg));
window.addEventListener('error', (e) => send({ type: 'error', message: String(e.message) }));

const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setClearColor(0x000000, 0);
document.body.appendChild(renderer.domElement);

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(CAMERA_FOV, 1, 0.05, 500);
const controls = new OrbitControls(camera, renderer.domElement);
controls.enablePan = false;
const clock = new THREE.Clock();

let mixer = null;
let model = null;
let rootBone = null;
const clips = new Map(); // nombre → AnimationClip
const floorTracks = new Map(); // nombre → pista de posición del root.x

let plan = null;
// Clips que todavía pesan en la mezcla: { index, action, clip, offsetX, offsetZ,
// interpolant, fadeFrom, fadeTo, fadeStart, advancing }.
let entries = [];
let current = null;
const floor = { x: 0, z: 0 };
// Reloj de las mezclas: se para con la pausa, igual que las animaciones.
let blendTime = 0;
// Zona encuadrada, para volver a encuadrar si cambia el tamaño del visor.
let framedBounds = null;

function resize() {
  const w = window.innerWidth;
  const h = window.innerHeight;
  renderer.setSize(w, h, false);
  camera.aspect = w / Math.max(h, 1);
  camera.updateProjectionMatrix();
  if (framedBounds) frameCamera(framedBounds);
}
window.addEventListener('resize', resize);
resize();

new GLTFLoader().load(
  './animations.glb',
  (gltf) => {
    model = gltf.scene;
    // Oculto hasta encuadrar la cámara en ppLoad: si no, se vería un instante
    // en la pose de reposo desde la cámara por defecto.
    model.visible = false;
    scene.add(model);
    model.updateMatrixWorld(true);
    rootBone = model.getObjectByName(THREE.PropertyBinding.sanitizeNodeName(ROOT_BONE));
    if (!rootBone) {
      send({ type: 'error', message: 'El archivo no trae el hueso ' + ROOT_BONE });
      return;
    }
    mixer = new THREE.AnimationMixer(model);
    for (const clip of gltf.animations) {
      clips.set(clip.name, clip);
      const track = clip.tracks.find((t) => t.name === rootBone.name + '.position');
      if (track) floorTracks.set(clip.name, track);
    }
    send({ type: 'ready' });
  },
  undefined,
  (e) => send({ type: 'error', message: String(e?.message ?? e) }),
);

// Primer paso reproducible desde index, buscando hacia delante (direction 1)
// o hacia atrás (-1, para ◀).
function playableFrom(index, direction = 1) {
  const n = plan.steps.length;
  for (let k = 0; k < n; k++) {
    const i = (((index + direction * k) % n) + n) % n;
    if (plan.steps[i].playable && clips.has(plan.steps[i].clip)) return i;
  }
  return -1;
}

function startStep(index, offsetX, offsetZ) {
  const step = plan.steps[index];
  // Un clip propio por paso: three.js guarda una acción por clip, y un golpe
  // repetido seguido se fundiría consigo mismo.
  const clip = clips.get(step.clip).clone();
  const action = mixer.clipAction(clip);
  action.setLoop(THREE.LoopOnce, 1);
  action.clampWhenFinished = true;
  action.reset().play();
  // Lo que sonaba baja desde el peso que tenga ahora; el primer paso entra
  // entero y los demás suben desde 0.
  for (const e of entries) fade(e, weightOf(e), 0);
  const track = floorTracks.get(step.clip);
  current = { index, action, clip, offsetX, offsetZ, interpolant: track?.createInterpolant() };
  fade(current, entries.length === 0 ? 1 : 0, 1);
  entries.push(current);
  applyWeights();
  send({ type: 'playing', index });
}

function fade(entry, from, to) {
  entry.fadeFrom = from;
  entry.fadeTo = to;
  entry.fadeStart = blendTime;
}

function weightOf(entry) {
  const t = Math.min(Math.max((blendTime - entry.fadeStart) / BLEND, 0), 1);
  return entry.fadeFrom + (entry.fadeTo - entry.fadeFrom) * t;
}

function applyWeights() {
  for (const e of entries) e.action.setEffectiveWeight(weightOf(e));
}

function advanceIfEnding() {
  if (!current || current.advancing) return;
  if (current.action.time < current.clip.duration - BLEND) return;
  current.advancing = true;
  const next = playableFrom((current.index + 1) % plan.steps.length);
  const step = plan.steps[next];
  // Al dar la vuelta se usa el desplazamiento del primer paso del plan: el
  // jugador regresa al inicio en vez de alejarse en cada repetición.
  if (next <= current.index) {
    startStep(next, step.offsetX, step.offsetZ);
    return;
  }
  // Si no, empieza donde termina el actual. Se calcula aquí y no con los del
  // plan para que siga encadenado también después de saltar con ◀ / ▶.
  const end = endOf(current);
  startStep(next, end.x - step.startX, end.z - step.startZ);
}

// Dónde queda en el suelo el último fotograma de un paso ya desplazado.
function endOf(entry) {
  if (!entry.interpolant) return { x: floor.x, z: floor.z };
  const p = entry.interpolant.evaluate(entry.clip.duration);
  return { x: p[0] + entry.offsetX, z: p[2] + entry.offsetZ };
}

// Posición en el suelo: media de las posiciones (pista + desplazamiento) de
// los clips que se están mezclando, con sus pesos.
function placeOnFloor() {
  let x = 0;
  let z = 0;
  let total = 0;
  for (const e of entries) {
    const w = weightOf(e);
    if (w <= 0 || !e.interpolant) continue;
    const p = e.interpolant.evaluate(Math.min(e.action.time, e.clip.duration));
    x += w * (p[0] + e.offsetX);
    z += w * (p[2] + e.offsetZ);
    total += w;
  }
  if (total > 0) {
    floor.x = x / total;
    floor.z = z / total;
  }
  rootBone.position.x = floor.x;
  rootBone.position.z = floor.z;
}

function dropFinishedEntries() {
  entries = entries.filter((e) => {
    if (e === current || weightOf(e) > 0) return true;
    e.action.stop();
    mixer.uncacheClip(e.clip);
    return false;
  });
}

function frameCamera(bounds) {
  model.updateMatrixWorld(true);
  const parent = rootBone.parent;
  // De los pies a la cabeza: la cadera queda más o menos a media altura.
  const top = rootBone.position.y * 2;
  const box = new THREE.Box3();
  for (const x of [bounds.minX, bounds.maxX]) {
    for (const z of [bounds.minZ, bounds.maxZ]) {
      for (const y of [0, top]) box.expandByPoint(parent.localToWorld(new THREE.Vector3(x, y, z)));
    }
  }
  const center = box.getCenter(new THREE.Vector3());
  const radius = box.getBoundingSphere(new THREE.Sphere()).radius;
  // El ángulo más estrecho de los dos: en un visor más alto que ancho manda
  // el horizontal, y con solo el vertical se cortarían los lados.
  const vFov = THREE.MathUtils.degToRad(CAMERA_FOV);
  const hFov = 2 * Math.atan(Math.tan(vFov / 2) * camera.aspect);
  const distance = (radius * FRAME_MARGIN) / Math.sin(Math.min(vFov, hFov) / 2);
  const offset = new THREE.Vector3().setFromSphericalCoords(distance, CAMERA_PHI, CAMERA_THETA);
  camera.position.copy(center).add(offset);
  // Límites del zoom con los dedos: más allá el modelo desaparecería.
  controls.minDistance = distance * MIN_ZOOM;
  controls.maxDistance = distance * MAX_ZOOM;
  camera.near = Math.max(distance / 100, 0.01);
  camera.far = distance * MAX_ZOOM + radius * 2;
  camera.updateProjectionMatrix();
  controls.target.copy(center);
  controls.update();
  framedBounds = bounds;
}

window.ppLoad = (newPlan) => {
  if (!mixer) return;
  mixer.stopAllAction();
  for (const e of entries) mixer.uncacheClip(e.clip);
  entries = [];
  current = null;
  plan = newPlan;
  const first = playableFrom(0);
  if (first === -1 || !plan.bounds) {
    send({ type: 'error', message: 'Ningún golpe del ejercicio está en el archivo' });
    return;
  }
  frameCamera(plan.bounds);
  model.visible = true;
  mixer.timeScale = 1;
  startStep(first, plan.steps[first].offsetX, plan.steps[first].offsetZ);
};

// Saltar a un paso continúa desde donde está el jugador.
window.ppGoTo = (index, direction = 1) => {
  if (!plan) return;
  const i = playableFrom(index, direction);
  if (i === -1) return;
  const step = plan.steps[i];
  startStep(i, floor.x - step.startX, floor.z - step.startZ);
  mixer.timeScale = 1;
};

window.ppPause = () => {
  if (mixer) mixer.timeScale = 0;
};

window.ppResume = () => {
  if (mixer) mixer.timeScale = 1;
};

function tick() {
  requestAnimationFrame(tick);
  const dt = clock.getDelta();
  if (mixer && plan && current) {
    blendTime += dt * mixer.timeScale;
    applyWeights();
    mixer.update(dt);
    advanceIfEnding();
    placeOnFloor();
    dropFinishedEntries();
  }
  controls.update();
  renderer.render(scene, camera);
}
tick();
