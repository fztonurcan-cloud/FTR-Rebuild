import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { DRACOLoader } from 'three/examples/jsm/loaders/DRACOLoader.js';

const BASE = import.meta.env.BASE_URL || './';
const QA_MODE = new URLSearchParams(window.location.search).get('qa') === '1';
const IS_COMPACT = matchMedia('(max-width: 760px)').matches;
const LOW_POWER = IS_COMPACT || (navigator.deviceMemory && navigator.deviceMemory <= 4);

const MODEL_FILES = {
  muscle: `${BASE}models/muscular.glb`,
  ligament: `${BASE}models/ligaments.glb`,
  vessel: `${BASE}models/cardiovascular.glb`,
  bone: `${BASE}models/skeleton.glb`
};
const SYSTEM_LABELS = { muscle: 'Kaslar', ligament: 'Ligamentler', vessel: 'Damarlar', bone: 'Kemikler' };
const SYSTEM_BADGES = { muscle: 'KAS', ligament: 'LİGAMENT', vessel: 'DAMAR', bone: 'KEMİK' };
const SYSTEM_COLORS = { muscle: 0xe16450, ligament: 0xa765ff, vessel: 0x22a9ef, bone: 0xe8eff8 };

const BICEPS = {
  subtitle: 'İki başlı kol kası',
  general: 'Biceps brachii, ön kolun supinasyonunda ve dirseğin fleksiyonunda görev alan iki başlı bir kastır.',
  origin: 'Caput longum: tuberculum supraglenoidale; caput breve: processus coracoideus.',
  insertion: 'Tuberositas radii ve aponeurosis bicipitalis.',
  innervation: 'N. musculocutaneus (C5–C6).',
  function: 'Dirsek fleksiyonu ve ön kol supinasyonunun güçlü kasıdır; omuz fleksiyonuna yardımcı olur.'
};

const canvas = document.getElementById('anatomyCanvas');
const viewer = document.getElementById('viewer');
const loading = document.getElementById('loading');
const structureName = document.getElementById('structureName');
const structureSubtitle = document.getElementById('structureSubtitle');
const structureText = document.getElementById('structureText');
const structureSystem = document.getElementById('structureSystem');
const systemHeading = document.getElementById('systemHeading');

let scene;
let camera;
let renderer;
let controls;
let raycaster;
let pointer;
let activeRoot = null;
let activeSystem = 'muscle';
let activeMeshes = [];
let selectedMesh = null;
let selectedOriginalMaterial = null;
let currentTab = 'general';
let metadata = {};
let loadSequence = 0;
let renderHandle = 0;
let renderFrames = 0;

const highlightMaterial = new THREE.MeshStandardMaterial({
  color: 0x2f83ff,
  emissive: 0x0c45c9,
  emissiveIntensity: 1.25,
  roughness: 0.46,
  metalness: 0.01
});

function requestRender(frames = 1) {
  renderFrames = Math.max(renderFrames, frames);
  if (!renderHandle) renderHandle = requestAnimationFrame(renderFrame);
}

function renderFrame() {
  renderHandle = 0;
  if (!renderer || !scene || !camera) return;
  controls.update();
  renderer.render(scene, camera);
  renderFrames--;
  if (renderFrames > 0) renderHandle = requestAnimationFrame(renderFrame);
}

function initThree() {
  scene = new THREE.Scene();
  camera = new THREE.PerspectiveCamera(34, 1, 0.01, 1000);
  camera.position.set(2.8, 1.2, 4.6);
  renderer = new THREE.WebGLRenderer({
    canvas,
    antialias: !LOW_POWER,
    alpha: true,
    powerPreference: 'high-performance',
    preserveDrawingBuffer: false
  });
  renderer.setPixelRatio(LOW_POWER ? 1 : Math.min(devicePixelRatio || 1, 1.5));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.08;

  controls = new OrbitControls(camera, canvas);
  controls.enableDamping = true;
  controls.dampingFactor = 0.1;
  controls.enablePan = false;
  controls.zoomToCursor = true;
  controls.minDistance = 0.25;
  controls.maxDistance = 14;
  controls.target.set(0, 1.05, 0);
  controls.addEventListener('start', () => requestRender(40));
  controls.addEventListener('change', () => requestRender(2));
  controls.addEventListener('end', () => requestRender(20));

  scene.add(new THREE.HemisphereLight(0xd8ecff, 0x1b1010, 2.15));
  const key = new THREE.DirectionalLight(0xffffff, 2.9);
  key.position.set(4, 6, 5);
  scene.add(key);
  const rim = new THREE.DirectionalLight(0x718cff, 1.5);
  rim.position.set(-5, 3, -4);
  scene.add(rim);

  raycaster = new THREE.Raycaster();
  pointer = new THREE.Vector2();
  resize();
  addEventListener('resize', resize);
  canvas.addEventListener('pointerup', handlePick);
  requestRender(2);
}

function resize() {
  if (!renderer || !viewer) return;
  const rect = viewer.getBoundingClientRect();
  renderer.setSize(Math.max(1, rect.width), Math.max(1, rect.height), false);
  camera.aspect = Math.max(0.2, rect.width / Math.max(1, rect.height));
  camera.updateProjectionMatrix();
  requestRender(2);
}

async function loadMetadata() {
  try {
    const response = await fetch(`${BASE}data/structures.json`, { cache: 'no-store' });
    if (response.ok) metadata = await response.json();
  } catch (_) {
    metadata = {};
  }
}

function loadModel(url) {
  const draco = new DRACOLoader();
  draco.setDecoderPath(`${BASE}draco/`);
  const loader = new GLTFLoader();
  loader.setDRACOLoader(draco);
  return new Promise((resolve, reject) => loader.load(
    url,
    gltf => { draco.dispose(); resolve(gltf.scene); },
    undefined,
    error => { draco.dispose(); reject(error); }
  ));
}

function prepRoot(root, system) {
  root.traverse(object => {
    if (!object.isMesh) return;
    object.castShadow = false;
    object.receiveShadow = false;
    object.userData.system = system;
    object.userData.displayName = prettyName(object.name);
    if (Array.isArray(object.material)) object.material = object.material.map(material => material.clone());
    else if (object.material) object.material = object.material.clone();
  });
}

function disposeRoot(root) {
  root?.traverse(object => {
    if (!object.isMesh) return;
    object.geometry?.dispose?.();
    if (Array.isArray(object.material)) object.material.forEach(material => material?.dispose?.());
    else object.material?.dispose?.();
  });
}

async function switchSystem(system, initial = false) {
  const sequence = ++loadSequence;
  activeSystem = system;
  systemHeading.textContent = SYSTEM_LABELS[system];
  structureSystem.textContent = SYSTEM_BADGES[system];
  document.querySelectorAll('.system-btn').forEach(button => button.classList.toggle('active', button.dataset.system === system));
  restoreSelection();
  if (activeRoot) {
    scene.remove(activeRoot);
    disposeRoot(activeRoot);
    activeRoot = null;
  }
  activeMeshes = [];
  loading.innerHTML = '<div class="spinner"></div><span>3D anatomi yükleniyor…</span>';
  loading.classList.remove('hidden');
  requestRender(2);

  try {
    const root = await loadModel(MODEL_FILES[system]);
    if (sequence !== loadSequence) {
      disposeRoot(root);
      return;
    }
    prepRoot(root, system);
    activeRoot = root;
    scene.add(root);
    activeMeshes = collectEligible(root);
    loading.classList.add('hidden');
    fitWholeBody();

    const preferred = system === 'muscle'
      ? findMesh(/^biceps brachii$/i)
      : system === 'bone'
        ? findMesh(/^fibula$/i)
        : activeMeshes[0];
    if (preferred) selectMesh(preferred, !initial && system === 'bone');
    requestRender(8);
  } catch (error) {
    console.error(error);
    if (sequence === loadSequence) loading.innerHTML = '<span>3D model yüklenemedi.</span>';
  }
}

function collectEligible(root) {
  const meshes = [];
  root.traverse(object => {
    if (!object.isMesh || !object.visible) return;
    const name = prettyName(object.name);
    if (!name || name.length < 2 || name.length > 90 || /collection|object|mesh|default|material/i.test(name)) return;
    meshes.push(object);
  });
  return meshes;
}

function prettyName(raw = '') {
  return String(raw)
    .replace(/_/g, ' ')
    .replace(/\.(00\d|0\d\d|\d\d\d)$/i, '')
    .replace(/\.(l|r)$/i, '')
    .replace(/\s{2,}/g, ' ')
    .trim();
}

function normalizeName(value) {
  return String(value || '').toLocaleLowerCase('en-US').replace(/[^a-z0-9]+/g, ' ').trim();
}

function findMesh(regex) {
  return activeMeshes.find(mesh => regex.test(prettyName(mesh.name))) || null;
}

function restoreSelection() {
  if (selectedMesh && selectedOriginalMaterial) selectedMesh.material = selectedOriginalMaterial;
  selectedMesh = null;
  selectedOriginalMaterial = null;
}

function selectMesh(mesh, shouldFocus = true) {
  if (!mesh?.isMesh) return;
  restoreSelection();
  selectedMesh = mesh;
  selectedOriginalMaterial = mesh.material;
  mesh.material = highlightMaterial;
  currentTab = 'general';
  document.querySelectorAll('.tab').forEach(tab => tab.classList.toggle('active', tab.dataset.tab === 'general'));
  updateInfo();
  if (shouldFocus) focusMesh(mesh);
  requestRender(5);
}

function updateInfo() {
  if (!selectedMesh) return;
  const name = prettyName(selectedMesh.name) || 'Anatomik yapı';
  const info = getInfo(name, activeSystem);
  structureName.textContent = info.title || name;
  structureSubtitle.textContent = info.subtitle;
  structureSystem.textContent = SYSTEM_BADGES[activeSystem];
  structureText.textContent = info[currentTab] || info.general;
}

function getInfo(name, system) {
  if (system === 'muscle' && /biceps\s*brachii/i.test(name)) return { title: 'Biceps brachii', ...BICEPS };
  const key = normalizeName(name);
  const entry = metadata?.[system]?.[key] || metadata?.[system]?.[name] || null;
  const fallback = fallbackInfo(name, system);
  if (!entry) return fallback;
  return {
    title: entry.tr || entry.name || name,
    subtitle: entry.subtitle || fallback.subtitle,
    general: entry.general || entry.description || fallback.general,
    origin: entry.origin || fallback.origin,
    insertion: entry.insertion || fallback.insertion,
    innervation: entry.innervation || fallback.innervation,
    function: entry.function || fallback.function
  };
}

function fallbackInfo(name, system) {
  if (system === 'bone') return {
    subtitle: 'İskelet sistemi yapısı',
    general: `${name}, iskelet sisteminin bir parçasıdır. Kemik; destek, eklem mekaniği ve yumuşak doku tutunmaları açısından incelenir.`,
    origin: 'Kemiklerde Origo sekmesi, bu kemikten başlayan kasların anatomik tutunma alanlarını ifade eder.',
    insertion: 'Kemiklerde Insertio sekmesi, bu kemiğe sonlanan kas ve ligament tutunmalarını ifade eder.',
    innervation: 'Kemik motor innervasyon almaz; periost ve eklem çevresi bölgesel duyusal sinir lifleriyle innerve edilir.',
    function: 'İskelet desteğine, hareket zincirine ve kas-ligament kuvvetlerinin aktarılmasına katkı sağlar.'
  };
  if (system === 'ligament') return {
    subtitle: 'Ligament yapısı',
    general: `${name}, eklem veya kemikler arasında pasif stabilite sağlayan bağ dokusu yapısıdır.`,
    origin: 'Ligamentlerde Origo, birinci kemik tutunma alanını ifade eder.',
    insertion: 'Ligamentlerde Insertio, karşı taraftaki kemik tutunma alanını ifade eder.',
    innervation: 'Ligamentler propriosepsiyon ve ağrı duyusuna katkı veren duyusal sinir uçları içerir.',
    function: 'Aşırı eklem hareketini sınırlar ve pasif stabiliteye katkı sağlar.'
  };
  if (system === 'vessel') return {
    subtitle: 'Damar sistemi yapısı',
    general: `${name}, dolaşım sisteminde kanın taşınmasına katılan anatomik damar yapısıdır.`,
    origin: 'Damar anatomisinde Origo, damarın kaynaklandığı ana damar veya başlangıç bölgesini ifade eder.',
    insertion: 'Damar anatomisinde Insertio yerine seyir, dallanma ve sonlanma ilişkileri değerlendirilir.',
    innervation: 'Damar duvarı otonom sinir sistemi tarafından düzenlenen düz kas lifleri içerir.',
    function: 'İlgili bölgenin arteriyel beslenmesine veya venöz drenajına katkı sağlar.'
  };
  return {
    subtitle: 'Kas sistemi yapısı',
    general: `${name}, kas sistemi içinde yer alan ve hareket üretimine katkı sağlayan anatomik yapıdır.`,
    origin: 'Origo, kasın görece daha sabit başlangıç tutunma alanıdır.',
    insertion: 'Insertio, kasın kasılma sırasında daha hareketli olan sonlanma tutunma alanıdır.',
    innervation: 'Kasın motor kontrolü periferik sinir sistemi üzerinden sağlanır.',
    function: 'Kasın fonksiyonu eklem konumuna, lif yönüne ve birlikte çalıştığı kaslara bağlıdır.'
  };
}

function handlePick(event) {
  if (!activeRoot || loading.classList.contains('hidden') === false) return;
  const rect = canvas.getBoundingClientRect();
  pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
  pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
  raycaster.setFromCamera(pointer, camera);
  const hit = raycaster.intersectObjects(activeMeshes, false)[0];
  if (hit?.object) selectMesh(hit.object, false);
}

function fitWholeBody() {
  if (!activeRoot) return;
  const box = new THREE.Box3().setFromObject(activeRoot);
  if (box.isEmpty()) return;
  const size = box.getSize(new THREE.Vector3());
  const center = box.getCenter(new THREE.Vector3());
  const maxDim = Math.max(size.x, size.y, size.z, .1);
  controls.target.copy(center.clone().add(new THREE.Vector3(0, size.y * .02, 0)));
  camera.position.set(center.x + maxDim * .9, center.y + size.y * .04, center.z + maxDim * 1.85);
  camera.near = Math.max(.002, maxDim / 200);
  camera.far = maxDim * 35;
  controls.minDistance = Math.max(.18, maxDim * .08);
  controls.maxDistance = maxDim * 8;
  camera.updateProjectionMatrix();
  controls.update();
  requestRender(8);
}

function focusMesh(mesh) {
  const box = new THREE.Box3().setFromObject(mesh);
  if (box.isEmpty()) return;
  const size = box.getSize(new THREE.Vector3());
  const center = box.getCenter(new THREE.Vector3());
  const maxDim = Math.max(size.x, size.y, size.z, .08);
  controls.target.copy(center);
  camera.position.copy(center).add(new THREE.Vector3(1.1, .34, 1.55).normalize().multiplyScalar(maxDim * 2.1 + .45));
  camera.near = Math.max(.002, maxDim / 120);
  camera.far = Math.max(40, maxDim * 70);
  camera.updateProjectionMatrix();
  controls.update();
  requestRender(12);
}

function zoom(multiplier) {
  const direction = camera.position.clone().sub(controls.target);
  const next = direction.length() * multiplier;
  const limited = THREE.MathUtils.clamp(next, controls.minDistance, controls.maxDistance);
  camera.position.copy(controls.target).add(direction.normalize().multiplyScalar(limited));
  controls.update();
  requestRender(12);
}

function rotateQuarter() {
  if (!activeRoot) return;
  const start = activeRoot.rotation.y;
  const target = start + Math.PI / 4;
  const began = performance.now();
  const tick = now => {
    const t = Math.min(1, (now - began) / 260);
    activeRoot.rotation.y = THREE.MathUtils.lerp(start, target, 1 - Math.pow(1 - t, 3));
    requestRender(1);
    if (t < 1) requestAnimationFrame(tick);
  };
  requestAnimationFrame(tick);
}

function bindUi() {
  document.querySelectorAll('.system-btn').forEach(button => button.addEventListener('click', () => switchSystem(button.dataset.system)));
  document.querySelectorAll('.tab').forEach(tab => tab.addEventListener('click', () => {
    currentTab = tab.dataset.tab;
    document.querySelectorAll('.tab').forEach(item => item.classList.toggle('active', item === tab));
    updateInfo();
  }));
  document.getElementById('rotateBtn').addEventListener('click', rotateQuarter);
  document.getElementById('zoomInBtn').addEventListener('click', () => zoom(.78));
  document.getElementById('zoomOutBtn').addEventListener('click', () => zoom(1.28));
  document.getElementById('resetBtn').addEventListener('click', fitWholeBody);
  document.getElementById('backBtn').addEventListener('click', () => history.back());
  document.querySelectorAll('.bottom-nav button').forEach((button, index) => button.addEventListener('click', () => {
    if (index === 0) history.back();
  }));
}

async function init() {
  bindUi();
  initThree();
  await loadMetadata();
  await switchSystem('muscle', true);
}

if (QA_MODE) {
  window.__FTR_ANATOMY_QA__ = {
    state() {
      return {
        activeSystem,
        activeMeshCount: activeMeshes.length,
        selectedStructure: selectedMesh ? prettyName(selectedMesh.name) : '',
        selectedHighlighted: Boolean(selectedMesh && selectedMesh.material === highlightMaterial),
        cameraDistance: camera && controls ? camera.position.distanceTo(controls.target) : null,
        pixelRatio: renderer?.getPixelRatio?.() || null,
        continuousAnimation: false,
        activeRotationY: activeRoot?.rotation?.y || 0,
        loadSequence
      };
    },
    pick(regexText) {
      const mesh = findMesh(new RegExp(regexText, 'i')) || activeMeshes[0];
      if (mesh) selectMesh(mesh, false);
      return this.state();
    },
    pickDifferentStructure() {
      const mesh = activeMeshes.find(item => item !== selectedMesh);
      if (mesh) selectMesh(mesh, false);
      return this.state();
    }
  };
}

init();
