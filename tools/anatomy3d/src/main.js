import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { DRACOLoader } from 'three/examples/jsm/loaders/DRACOLoader.js';

const BASE = import.meta.env.BASE_URL || './';
const MODEL_FILES = {
  skeleton: `${BASE}models/skeleton.glb`,
  muscle: `${BASE}models/muscular.glb`,
  nerve: `${BASE}models/nervous.glb`,
  ligament: `${BASE}models/ligaments.glb`,
  vessel: `${BASE}models/cardiovascular.glb`
};
const SYSTEM_LABELS = {
  muscle: 'Kas Sistemi',
  nerve: 'Sinir Sistemi',
  ligament: 'Ligament Sistemi',
  vessel: 'Damar Sistemi'
};
const SYSTEM_COLORS = {
  muscle: 0xd65b45,
  nerve: 0xf0c433,
  ligament: 0x9a5cff,
  vessel: 0x1c9fff
};
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
const infoCard = document.getElementById('infoCard');
const quizCard = document.getElementById('quizCard');
const structureName = document.getElementById('structureName');
const structureSubtitle = document.getElementById('structureSubtitle');
const structureText = document.getElementById('structureText');
const systemHeading = document.getElementById('systemHeading');
const examBtn = document.getElementById('examBtn');
const quizSystem = document.getElementById('quizSystem');
const quizProgress = document.getElementById('quizProgress');
const quizScore = document.getElementById('quizScore');
const quizOptions = document.getElementById('quizOptions');
const quizFeedback = document.getElementById('quizFeedback');
const nextQuestionBtn = document.getElementById('nextQuestionBtn');

let scene, camera, renderer, controls, raycaster, pointer;
let skeletonRoot = null;
let activeRoot = null;
let activeSystem = 'muscle';
let activeMeshes = [];
let selectedMesh = null;
let selectedOriginalMaterial = null;
let autoRotate = false;
let labelsOn = false;
let currentTab = 'general';
let examMode = false;
let quizIndex = 0;
let quizScoreValue = 0;
let quizTarget = null;
let answered = false;
let quizPool = [];
let metadata = {};

const highlightMaterial = new THREE.MeshStandardMaterial({
  color: 0x307dff,
  emissive: 0x0f48ff,
  emissiveIntensity: 1.65,
  roughness: 0.42,
  metalness: 0.02,
  transparent: true,
  opacity: 0.96
});

function initThree() {
  scene = new THREE.Scene();
  scene.background = null;
  camera = new THREE.PerspectiveCamera(35, 1, 0.01, 1000);
  camera.position.set(2.8, 1.2, 4.6);

  renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true, preserveDrawingBuffer: true, powerPreference: 'high-performance' });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.15;

  controls = new OrbitControls(camera, canvas);
  controls.enableDamping = true;
  controls.dampingFactor = 0.08;
  controls.minDistance = 0.35;
  controls.maxDistance = 10;
  controls.target.set(0, 1.05, 0);

  scene.add(new THREE.HemisphereLight(0xcfe6ff, 0x170d0a, 2.3));
  const key = new THREE.DirectionalLight(0xffffff, 3.2);
  key.position.set(4, 6, 5);
  scene.add(key);
  const rim = new THREE.DirectionalLight(0x6e82ff, 2.0);
  rim.position.set(-5, 3, -4);
  scene.add(rim);
  const fill = new THREE.PointLight(0x7d46ff, 1.7, 10);
  fill.position.set(0, 2.5, 3);
  scene.add(fill);

  raycaster = new THREE.Raycaster();
  pointer = new THREE.Vector2();
  resize();
  window.addEventListener('resize', resize);
  canvas.addEventListener('pointerup', handlePick);
  animate();
}

function resize() {
  if (!renderer || !viewer) return;
  const rect = viewer.getBoundingClientRect();
  renderer.setSize(Math.max(1, rect.width), Math.max(1, rect.height), false);
  camera.aspect = Math.max(0.2, rect.width / Math.max(1, rect.height));
  camera.updateProjectionMatrix();
}

function animate() {
  requestAnimationFrame(animate);
  if (autoRotate && activeRoot) activeRoot.rotation.y += 0.004;
  controls.update();
  renderer.render(scene, camera);
}

function gltfLoader() {
  const draco = new DRACOLoader();
  draco.setDecoderPath(`${BASE}draco/`);
  const loader = new GLTFLoader();
  loader.setDRACOLoader(draco);
  return loader;
}

async function loadMetadata() {
  try {
    const res = await fetch(`${BASE}data/structures.json`, { cache: 'no-store' });
    if (res.ok) metadata = await res.json();
  } catch (_) {
    metadata = {};
  }
}

async function loadModel(url) {
  const loader = gltfLoader();
  return new Promise((resolve, reject) => loader.load(url, g => resolve(g.scene), undefined, reject));
}

function prepRoot(root, system) {
  root.traverse(obj => {
    if (!obj.isMesh) return;
    obj.castShadow = false;
    obj.receiveShadow = false;
    obj.userData.system = system;
    obj.userData.displayName = prettyName(obj.name);
    if (Array.isArray(obj.material)) obj.material = obj.material.map(m => m.clone());
    else if (obj.material) obj.material = obj.material.clone();
  });
}

async function loadSkeleton() {
  skeletonRoot = await loadModel(MODEL_FILES.skeleton);
  prepRoot(skeletonRoot, 'bone');
  skeletonRoot.traverse(obj => {
    if (!obj.isMesh || !obj.material) return;
    const mats = Array.isArray(obj.material) ? obj.material : [obj.material];
    mats.forEach(m => {
      if ('roughness' in m) m.roughness = 0.7;
      if ('metalness' in m) m.metalness = 0;
    });
  });
  scene.add(skeletonRoot);
  fitWholeBody();
}

async function switchSystem(system, initial = false) {
  activeSystem = system;
  systemHeading.textContent = SYSTEM_LABELS[system];
  document.querySelectorAll('.system-btn').forEach(b => b.classList.toggle('active', b.dataset.system === system));
  quizSystem.textContent = SYSTEM_LABELS[system].toLocaleUpperCase('tr-TR');
  restoreSelection();
  if (activeRoot) {
    scene.remove(activeRoot);
    disposeRoot(activeRoot);
  }
  activeMeshes = [];
  loading.classList.remove('hidden');
  try {
    activeRoot = await loadModel(MODEL_FILES[system]);
    prepRoot(activeRoot, system);
    scene.add(activeRoot);
    activeMeshes = collectEligible(activeRoot);
    loading.classList.add('hidden');
    if (initial && system === 'muscle') {
      const biceps = findMesh(/biceps[_ .-]*brachii/i) || activeMeshes[0];
      if (biceps) {
        selectMesh(biceps, false);
        focusMesh(biceps, 2.65);
      } else fitWholeBody();
    } else {
      fitWholeBody();
      const first = activeMeshes[0];
      if (first && !examMode) selectMesh(first, false);
    }
    if (examMode) startExam(true);
  } catch (err) {
    console.error(err);
    loading.innerHTML = '<span>3D model yüklenemedi. Paket dosyalarını kontrol edin.</span>';
  }
}

function collectEligible(root) {
  const seen = new Set();
  const list = [];
  root.traverse(obj => {
    if (!obj.isMesh || !obj.visible) return;
    const name = prettyName(obj.name);
    const key = normalizeName(name);
    if (!name || name.length < 3 || name.length > 72 || seen.has(key)) return;
    if (/collection|object|mesh|default|material/i.test(name)) return;
    seen.add(key);
    list.push(obj);
  });
  return list;
}

function disposeRoot(root) {
  root.traverse(obj => {
    if (!obj.isMesh) return;
    obj.geometry?.dispose?.();
    if (Array.isArray(obj.material)) obj.material.forEach(m => m?.dispose?.());
    else obj.material?.dispose?.();
  });
}

function prettyName(raw = '') {
  let name = String(raw).replace(/_/g, ' ').trim();
  name = name.replace(/\.(00\d|0\d\d|\d\d\d)$/i, '');
  name = name.replace(/\.(l|r)$/i, '');
  name = name.replace(/\s{2,}/g, ' ').trim();
  return name;
}

function normalizeName(name) {
  return String(name || '').toLocaleLowerCase('en-US').replace(/[^a-z0-9]+/g, ' ').trim();
}

function findMesh(regex) {
  return activeMeshes.find(m => regex.test(prettyName(m.name))) || null;
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
  updateInfo(mesh);
  if (shouldFocus) focusMesh(mesh, 2.2);
}

function updateInfo(mesh) {
  const name = prettyName(mesh.name) || 'Anatomik yapı';
  structureName.textContent = name;
  const isBiceps = /biceps\s*brachii/i.test(name);
  const info = getInfo(name, activeSystem, isBiceps);
  structureSubtitle.textContent = info.subtitle;
  structureText.textContent = info[currentTab] || info.general;
  if (labelsOn) showToast(name);
}

function getInfo(name, system, isBiceps = false) {
  if (isBiceps) return BICEPS;
  const key = normalizeName(name);
  const systemData = metadata?.[system] || {};
  const entry = systemData[key] || systemData[name] || null;
  if (entry) {
    return {
      subtitle: entry.tr || entry.subtitle || SYSTEM_LABELS[system],
      general: entry.general || entry.description || `${name}, ${SYSTEM_LABELS[system].toLocaleLowerCase('tr-TR')} içinde yer alan anatomik bir yapıdır.`,
      origin: entry.origin || 'Origo bilgisi akademik veri kartında gösterilir.',
      insertion: entry.insertion || 'Insertio bilgisi akademik veri kartında gösterilir.',
      innervation: entry.innervation || (system === 'muscle' ? 'İnnervasyon bilgisi akademik veri kartında gösterilir.' : 'Bu yapı için innervasyon alanı uygulanabilir değildir.'),
      function: entry.function || 'Fonksiyon ve klinik ilişki bilgisi akademik veri kartında gösterilir.'
    };
  }
  const subtitles = { muscle: 'Kas sistemi yapısı', nerve: 'Sinir sistemi yapısı', ligament: 'Ligament yapısı', vessel: 'Damar sistemi yapısı' };
  return {
    subtitle: subtitles[system],
    general: `${name}, 3D model üzerinde seçilmiş anatomik yapıdır. Yapıyı döndürerek farklı açılardan inceleyebilir veya sınav modunda tanımlayabilirsiniz.`,
    origin: system === 'muscle' ? 'Origo bilgisi FTR Akademi anatomi veri kartında gösterilir.' : 'Bu yapı için origo alanı uygulanabilir değildir.',
    insertion: system === 'muscle' ? 'Insertio bilgisi FTR Akademi anatomi veri kartında gösterilir.' : 'Bu yapı için insertio alanı uygulanabilir değildir.',
    innervation: system === 'muscle' ? 'İnnervasyon bilgisi FTR Akademi anatomi veri kartında gösterilir.' : 'Bu yapı için innervasyon alanı uygulanabilir değildir.',
    function: 'Fonksiyon ve klinik ilişki bilgisi FTR Akademi anatomi veri kartında gösterilir.'
  };
}

function handlePick(ev) {
  if (examMode || !activeRoot) return;
  const rect = canvas.getBoundingClientRect();
  pointer.x = ((ev.clientX - rect.left) / rect.width) * 2 - 1;
  pointer.y = -((ev.clientY - rect.top) / rect.height) * 2 + 1;
  raycaster.setFromCamera(pointer, camera);
  const hits = raycaster.intersectObjects(activeMeshes, false);
  if (hits[0]?.object) selectMesh(hits[0].object, false);
}

function fitWholeBody() {
  const root = skeletonRoot || activeRoot;
  if (!root) return;
  const box = new THREE.Box3().setFromObject(root);
  if (box.isEmpty()) return;
  const size = box.getSize(new THREE.Vector3());
  const center = box.getCenter(new THREE.Vector3());
  const maxDim = Math.max(size.x, size.y, size.z);
  controls.target.copy(center.clone().add(new THREE.Vector3(0, size.y * 0.03, 0)));
  camera.position.set(center.x + maxDim * 1.15, center.y + size.y * 0.05, center.z + maxDim * 2.1);
  camera.near = Math.max(0.001, maxDim / 200);
  camera.far = maxDim * 30;
  camera.updateProjectionMatrix();
  controls.update();
}

function focusMesh(mesh, distanceFactor = 2.2) {
  const box = new THREE.Box3().setFromObject(mesh);
  if (box.isEmpty()) return;
  const size = box.getSize(new THREE.Vector3());
  const center = box.getCenter(new THREE.Vector3());
  const maxDim = Math.max(size.x, size.y, size.z, 0.08);
  controls.target.copy(center);
  const dir = new THREE.Vector3(1.15, 0.38, 1.5).normalize();
  camera.position.copy(center).add(dir.multiplyScalar(maxDim * distanceFactor + 0.7));
  camera.near = Math.max(0.002, maxDim / 100);
  camera.far = Math.max(50, maxDim * 80);
  camera.updateProjectionMatrix();
  controls.update();
}

function setView(view) {
  document.querySelectorAll('.view-btn').forEach(b => b.classList.toggle('active', b.dataset.view === view));
  if (view === 'all') {
    if (skeletonRoot) skeletonRoot.visible = true;
    if (activeRoot) activeRoot.visible = true;
    return;
  }
  if (view === 'bone') {
    if (skeletonRoot) skeletonRoot.visible = true;
    if (activeRoot) activeRoot.visible = false;
    return;
  }
  if (skeletonRoot) skeletonRoot.visible = true;
  if (view !== activeSystem) switchSystem(view);
  else if (activeRoot) activeRoot.visible = true;
}

function toggleExam() {
  examMode = !examMode;
  if (examMode) {
    examBtn.innerHTML = '<span>💡</span> Öğrenme Modu';
    infoCard.classList.add('hidden');
    quizCard.classList.remove('hidden');
    startExam(true);
  } else {
    examBtn.innerHTML = '<span>⌘</span> Sınav Modu';
    quizCard.classList.add('hidden');
    infoCard.classList.remove('hidden');
    restoreSelection();
    const biceps = activeSystem === 'muscle' ? findMesh(/biceps[_ .-]*brachii/i) : activeMeshes[0];
    if (biceps) selectMesh(biceps, false);
  }
}

function startExam(reset = false) {
  if (!activeMeshes.length) return;
  if (reset) {
    quizIndex = 0;
    quizScoreValue = 0;
    quizPool = shuffle([...activeMeshes]).slice(0, Math.min(20, activeMeshes.length));
  }
  nextQuestion();
}

function nextQuestion() {
  if (!examMode || !activeMeshes.length) return;
  restoreSelection();
  answered = false;
  quizFeedback.textContent = '';
  if (quizIndex >= quizPool.length) {
    quizFeedback.textContent = `Sınav tamamlandı: ${quizScoreValue} / ${quizPool.length} doğru.`;
    quizOptions.innerHTML = '';
    nextQuestionBtn.textContent = 'Sınavı Yeniden Başlat';
    nextQuestionBtn.dataset.restart = '1';
    return;
  }
  nextQuestionBtn.textContent = 'Sonraki Soru →';
  delete nextQuestionBtn.dataset.restart;
  quizTarget = quizPool[quizIndex];
  selectedMesh = quizTarget;
  selectedOriginalMaterial = quizTarget.material;
  quizTarget.material = highlightMaterial;
  focusMesh(quizTarget, 2.4);
  const correct = prettyName(quizTarget.name);
  const choices = makeChoices(correct);
  quizOptions.innerHTML = '';
  choices.forEach(label => {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'quiz-option';
    btn.textContent = label;
    btn.addEventListener('click', () => answerQuestion(btn, label, correct));
    quizOptions.appendChild(btn);
  });
  quizProgress.textContent = `Soru ${quizIndex + 1} / ${quizPool.length}`;
  quizScore.textContent = `${quizScoreValue} doğru`;
}

function makeChoices(correct) {
  const names = activeMeshes.map(m => prettyName(m.name)).filter(n => n && normalizeName(n) !== normalizeName(correct));
  const unique = [...new Map(names.map(n => [normalizeName(n), n])).values()];
  const distractors = shuffle(unique).slice(0, 3);
  return shuffle([correct, ...distractors]);
}

function answerQuestion(button, answer, correct) {
  if (answered) return;
  answered = true;
  const ok = normalizeName(answer) === normalizeName(correct);
  if (ok) {
    quizScoreValue++;
    button.classList.add('correct');
    quizFeedback.textContent = `✓ Doğru: ${correct}`;
  } else {
    button.classList.add('wrong');
    quizFeedback.textContent = `✕ Yanlış. Doğru cevap: ${correct}`;
    [...quizOptions.children].forEach(b => {
      if (normalizeName(b.textContent) === normalizeName(correct)) b.classList.add('correct');
    });
  }
  quizScore.textContent = `${quizScoreValue} doğru`;
}

function shuffle(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

function showToast(message) {
  let toast = document.getElementById('anatomyToast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'anatomyToast';
    Object.assign(toast.style, { position:'fixed', left:'50%', top:'82px', transform:'translateX(-50%)', zIndex:'99', background:'rgba(10,18,31,.96)', border:'1px solid #34445f', color:'#fff', padding:'9px 13px', borderRadius:'11px', fontSize:'12px', boxShadow:'0 10px 28px rgba(0,0,0,.35)' });
    document.body.appendChild(toast);
  }
  toast.textContent = message;
  toast.style.display = 'block';
  clearTimeout(showToast.timer);
  showToast.timer = setTimeout(() => { toast.style.display = 'none'; }, 1800);
}

function bindUi() {
  document.querySelectorAll('.system-btn').forEach(btn => btn.addEventListener('click', () => switchSystem(btn.dataset.system)));
  document.querySelectorAll('.view-btn').forEach(btn => btn.addEventListener('click', () => setView(btn.dataset.view)));
  document.querySelectorAll('.tab').forEach(btn => btn.addEventListener('click', () => {
    currentTab = btn.dataset.tab;
    document.querySelectorAll('.tab').forEach(x => x.classList.toggle('active', x === btn));
    if (selectedMesh) updateInfo(selectedMesh);
  }));
  document.getElementById('rotateBtn').addEventListener('click', () => { autoRotate = !autoRotate; showToast(autoRotate ? 'Otomatik döndürme açık' : 'Otomatik döndürme kapalı'); });
  document.getElementById('zoomInBtn').addEventListener('click', () => { camera.position.lerp(controls.target, 0.18); });
  document.getElementById('zoomOutBtn').addEventListener('click', () => { camera.position.sub(controls.target).multiplyScalar(1.22).add(controls.target); });
  document.getElementById('resetBtn').addEventListener('click', fitWholeBody);
  document.getElementById('labelsBtn').addEventListener('click', () => { labelsOn = !labelsOn; showToast(labelsOn ? 'Etiketler açık' : 'Etiketler kapalı'); });
  document.getElementById('noteBtn').addEventListener('click', () => {
    const name = selectedMesh ? prettyName(selectedMesh.name) : '3D Anatomi';
    const note = window.prompt(`${name} için not:`);
    if (note) {
      localStorage.setItem(`ftr_anatomy_note_${normalizeName(name)}`, note);
      showToast('Not kaydedildi');
    }
  });
  document.getElementById('shotBtn').addEventListener('click', () => {
    try {
      const a = document.createElement('a');
      a.href = renderer.domElement.toDataURL('image/png');
      a.download = 'FTR-Akademi-3D-Anatomi.png';
      a.click();
      showToast('3D ekran görüntüsü hazırlandı');
    } catch (_) { showToast('Ekran görüntüsü bu cihazda desteklenmiyor'); }
  });
  document.getElementById('shareBtn').addEventListener('click', async () => {
    const text = selectedMesh ? `FTR Akademi 3D Anatomi: ${prettyName(selectedMesh.name)}` : 'FTR Akademi 3D Anatomi';
    try { if (navigator.share) await navigator.share({ title:'FTR Akademi', text }); else showToast(text); } catch (_) {}
  });
  document.getElementById('speakBtn').addEventListener('click', () => {
    if (!('speechSynthesis' in window)) return showToast('Sesli okuma desteklenmiyor');
    speechSynthesis.cancel();
    const u = new SpeechSynthesisUtterance(`${structureName.textContent}. ${structureText.textContent}`);
    u.lang = 'tr-TR';
    speechSynthesis.speak(u);
  });
  document.getElementById('favoriteBtn').addEventListener('click', ev => {
    const name = selectedMesh ? prettyName(selectedMesh.name) : structureName.textContent;
    const key = `ftr_anatomy_fav_${normalizeName(name)}`;
    const on = localStorage.getItem(key) !== '1';
    localStorage.setItem(key, on ? '1' : '0');
    ev.currentTarget.textContent = on ? 'Favorilere Eklendi ♥' : 'Favorilere Ekle ♡';
    showToast(on ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı');
  });
  examBtn.addEventListener('click', toggleExam);
  nextQuestionBtn.addEventListener('click', () => {
    if (nextQuestionBtn.dataset.restart) return startExam(true);
    if (!answered) return showToast('Önce bir cevap seç');
    quizIndex++;
    nextQuestion();
  });
  document.getElementById('backBtn').addEventListener('click', () => history.back());
  document.querySelectorAll('.bottom-nav button').forEach((btn, i) => btn.addEventListener('click', () => {
    if (i === 0) history.back();
    else showToast('Ana uygulama menüsüne dönülüyor');
  }));
}

async function init() {
  bindUi();
  initThree();
  await loadMetadata();
  try {
    await loadSkeleton();
    await switchSystem('muscle', true);
  } catch (err) {
    console.error(err);
    loading.innerHTML = '<span>3D anatomi verileri yüklenemedi.</span>';
  }
}

init();
