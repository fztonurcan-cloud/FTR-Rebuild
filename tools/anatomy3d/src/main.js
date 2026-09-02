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
  bone: `${BASE}models/skeleton.glb`,
  ligament: `${BASE}models/ligaments.glb`,
  vessel: `${BASE}models/cardiovascular.glb`,
  nerve: `${BASE}models/nervous.glb`
};
const REFERENCE_MODEL = `${BASE}models/skeleton-reference.glb`;
const REFERENCE_SYSTEMS = new Set(['ligament', 'vessel', 'nerve']);

const SYSTEMS = {
  muscle: { label: 'Kaslar', title: 'KAS SİSTEMİ', badge: 'KAS', placeholder: 'Kas ara...', icon: '◒' },
  bone: { label: 'Kemikler', title: 'KEMİK SİSTEMİ', badge: 'KEMİK', placeholder: 'Kemik ara...', icon: '◇' },
  ligament: { label: 'Ligamentler', title: 'LİGAMENT SİSTEMİ', badge: 'LİGAMENT', placeholder: 'Ligament ara...', icon: '✦' },
  vessel: { label: 'Damarlar', title: 'DAMAR SİSTEMİ', badge: 'DAMAR', placeholder: 'Damar ara...', icon: '◉' },
  nerve: { label: 'Sinirler', title: 'SİNİR SİSTEMİ', badge: 'SİNİR', placeholder: 'Sinir ara...', icon: '☀' }
};

const TAB_CONFIG = {
  muscle: [
    ['general', 'Genel Bilgi'], ['origin', 'Origo'], ['insertion', 'Insertio'], ['innervation', 'İnnervasyon'], ['function', 'Fonksiyon']
  ],
  bone: [
    ['general', 'Genel Bilgi'], ['features', 'Anatomik Özellikler'], ['articulations', 'Eklemleşmeler'], ['attachments', 'Kas - Ligament Tutunmaları'], ['clinical', 'Klinik Önemi']
  ],
  ligament: [
    ['general', 'Genel Bilgi'], ['attachments', 'Başlangıç - Tutunma'], ['connections', 'Bağladığı Yapılar'], ['function', 'Fonksiyon'], ['clinical', 'Klinik Önemi']
  ],
  vessel: [
    ['general', 'Genel Bilgi'], ['origin', 'Başlangıç'], ['course', 'Seyir'], ['branches', 'Dalları'], ['supply', 'Beslediği Bölge'], ['clinical', 'Klinik Önemi']
  ],
  nerve: [
    ['general', 'Genel Bilgi'], ['anatomy', 'Anatomi'], ['course', 'Seyir'], ['branches', 'Dalları'], ['innervation', 'İnnervasyon'], ['function', 'Fonksiyon'], ['clinical', 'Klinik Önemi']
  ]
};

const SPECIAL_INFO = [
  {
    system: 'muscle', match: /biceps\s*brachii/i,
    info: {
      title: 'Biceps brachii', subtitle: 'İki başlı kol kası',
      general: 'Biceps brachii, ön kolun supinasyonunda ve dirsek ekleminde fleksiyonda önemli rol alan iki başlı bir kastır. Uzun ve kısa başları skapuladan başlar ve ortak tendonla radiusa tutunur.',
      origin: 'Caput longum: tuberculum supraglenoidale scapulae. Caput breve: processus coracoideus scapulae.',
      insertion: 'Tuberositas radii ve aponeurosis bicipitalis.',
      innervation: 'N. musculocutaneus (C5–C6; katkı C7 olabilir).',
      function: 'Ön kol supinasyonu ve dirsek fleksiyonu; omuz fleksiyonuna yardımcı olur.',
      facts: [['Tip', 'İskelet kası'], ['Bölge', 'Üst kol (Anterior)'], ['Kanlanma', 'A. brachialis dalları'], ['Sinir', 'N. musculocutaneus (C5–C6)']]
    }
  },
  {
    system: 'bone', match: /^fibula(?:\s|$)/i,
    info: {
      title: 'Fibula (Kamış kemiği)', subtitle: 'Alt ekstremite kemiği',
      general: 'Fibula, bacağın lateralinde yer alan ince ve uzun kemiktir. Tibia ile birlikte alt bacağın stabilitesine katkı sağlar; vücut ağırlığının yalnız küçük bir bölümünü taşır.',
      features: 'Baş, boyun ve gövdeden oluşur; distal ucu lateral malleolü meydana getirir. Fibula boynu, n. fibularis communis ile yakın komşuluktadır.',
      articulations: 'Proksimalde tibia ile proximal tibiofibular eklemde, distalde tibia ile distal tibiofibular sindesmozda ilişkilidir. Lateral malleol talusla ayak bileği eklemine katılır.',
      attachments: 'Biceps femoris tendonu fibula başına; lig. collaterale fibulare fibula başına tutunur. Fibularis longus/brevis, soleus, tibialis posterior ve bazı ekstansör/fleksör kaslar fibuladan köken alır.',
      clinical: 'Fibula boynu kırıkları n. fibularis communis yaralanması açısından önemlidir. Lateral malleol kırıkları ayak bileği stabilitesini etkileyebilir.',
      facts: [['Tip', 'Uzun kemik'], ['Bölge', 'Alt bacak (Lateral)'], ['Kanlanma', 'A. fibularis / periostal dallar'], ['Komşuluk', 'N. fibularis communis']]
    }
  },
  {
    system: 'ligament', match: /anterior\s+talofibular|talofibular\s+anterior|atfl/i,
    info: {
      title: 'Anterior talofibular ligament (ATFL)', subtitle: 'Dış yan bağ (Ayak bileği)',
      general: 'Anterior talofibular ligament, ayak bileğinin lateral bağ kompleksinin en sık yaralanan bileşenidir ve özellikle plantar fleksiyon ile inversiyon sırasında lateral stabiliteye katkı sağlar.',
      attachments: 'Fibulanın lateral malleolünün ön kenarından talusun boyun bölgesinin lateral yüzüne uzanır.',
      connections: 'Fibula ile talusu bağlar ve calcaneofibular ile posterior talofibular ligamentlerle birlikte lateral bağ kompleksini oluşturur.',
      function: 'Talusun öne translasyonunu ve aşırı inversiyonu sınırlar; ayak bileğinin lateral pasif stabilitesine katkı sağlar.',
      clinical: 'İnversiyon tipi ayak bileği burkulmalarında en sık etkilenen ligamenttir. Anterior drawer testi ATFL bütünlüğünün klinik değerlendirmesinde kullanılır.',
      facts: [['Tip', 'Fibröz bağ'], ['Bölge', 'Ayak bileği (Lateral)'], ['Başlangıç', 'Fibula / lateral malleol'], ['Tutunma', 'Talus / lateral yüz']]
    }
  },
  {
    system: 'vessel', match: /anterior\s+tibial\s+arter/i,
    info: {
      title: 'Anterior tibial artery', subtitle: 'Alt ekstremite arteri',
      general: 'Anterior tibial artery, popliteal arterin terminal dallarından biridir. Bacağın ön kompartmanını besler ve ayak bileği seviyesinde a. dorsalis pedis olarak devam eder.',
      origin: 'A. poplitea, popliteus kasının distal kenarı civarında anterior ve posterior tibial arterlere ayrılır.',
      course: 'İnterosseöz membranın proksimal açıklığından ön kompartmana geçer; interosseöz membran boyunca aşağı doğru seyreder ve ayak bileğinin önünden geçer.',
      branches: 'Anterior tibial recurrent, anterior medial ve lateral malleolar dallar ile kas dalları verir; distalde a. dorsalis pedis olarak devam eder.',
      supply: 'Bacağın anterior kompartman kasları ile ayak sırtının arteriyel dolaşımına katkı sağlar.',
      clinical: 'Dorsalis pedis nabzı periferik dolaşım değerlendirmesinde kullanılır. Travma ve kompartman sendromunda damar bütünlüğü klinik önem taşır.',
      facts: [['Tip', 'Arter'], ['Bölge', 'Alt ekstremite'], ['Başlangıç', 'A. poplitea'], ['Devamı', 'A. dorsalis pedis']]
    }
  },
  {
    system: 'nerve', match: /median\s+nerve|n\.\s*medianus|median\s+sinir/i,
    info: {
      title: 'Median sinir', subtitle: 'Brakiyal pleksus (C5–T1)',
      general: 'Median sinir, brakiyal pleksusun lateral ve medial kordlarından köken alan karma bir periferik sinirdir. Ön kol ve elin önemli motor ve duyusal fonksiyonlarını taşır.',
      anatomy: 'Radix lateralis ve radix medialis n. mediani birleşerek median siniri oluşturur; kök katkıları genellikle C5–T1 segmentlerindendir.',
      course: 'Kolda a. brachialis ile seyreder, kubital fossadan ön kola geçer ve fleksör kaslar arasında ilerleyerek karpal tünelden ele ulaşır.',
      branches: 'Ön kolda kas dalları ve n. interosseus anterior; elde rekürren tenar dal ve palmar/dijital dallar verir.',
      innervation: 'Ön kol fleksör-pronator grubunun çoğu, tenar kasların önemli bölümü ve lateral iki lumbrikal kas; elde lateral palmar yüzün duyusu.',
      function: 'El bileği ve parmak fleksiyonu, pronasyon, başparmak opponens hareketi ve radial tarafta hassas kavrama ile duyusal geri bildirime katkı sağlar.',
      clinical: 'Karpal tünel sendromu median sinirin en sık kompresyon tablolarındandır; tenar güçsüzlük ve radial üç buçuk parmakta parestezi görülebilir.',
      facts: [['Tip', 'Karma sinir'], ['Kök', 'C5–T1'], ['Seyir', 'Kol → Ön kol → Karpal tünel → El'], ['Klinik', 'Karpal tünel ilişkisi']]
    }
  }
];

const app = document.getElementById('anatomy-app');
const canvas = document.getElementById('anatomyCanvas');
const viewer = document.getElementById('viewer');
const loading = document.getElementById('loading');
const structureName = document.getElementById('structureName');
const structureSubtitle = document.getElementById('structureSubtitle');
const structureText = document.getElementById('structureText');
const structureSystem = document.getElementById('structureSystem');
const systemSubtitle = document.getElementById('systemSubtitle');
const browserHeading = document.getElementById('browserHeading');
const structureSearch = document.getElementById('structureSearch');
const structureList = document.getElementById('structureList');
const tabs = document.getElementById('tabs');
const factGrid = document.getElementById('factGrid');
const modelLabel = document.getElementById('modelLabel');
const modelLabelText = document.getElementById('modelLabelText');
const previewIcon = document.getElementById('previewIcon');

let scene;
let camera;
let renderer;
let controls;
let raycaster;
let pointer;
let activeRoot = null;
let referenceRoot = null;
let activeSystem = 'muscle';
let activeMeshes = [];
let selectedMesh = null;
let currentTab = 'general';
let metadata = {};
let loadSequence = 0;
let renderHandle = 0;
let autoRotateHandle = 0;
let autoRotate = false;
let layersIsolated = false;
let transparencyEnabled = false;

const MATERIALS = {
  muscle: new THREE.MeshStandardMaterial({ color: 0xb93d30, roughness: .68, metalness: 0 }),
  tendon: new THREE.MeshStandardMaterial({ color: 0xe8dfcf, roughness: .78, metalness: 0 }),
  bone: new THREE.MeshStandardMaterial({ color: 0xe2d6bd, roughness: .72, metalness: 0 }),
  ligament: new THREE.MeshStandardMaterial({ color: 0xd8d2c6, roughness: .72, metalness: 0 }),
  artery: new THREE.MeshStandardMaterial({ color: 0xd72f39, roughness: .58, metalness: 0 }),
  vein: new THREE.MeshStandardMaterial({ color: 0x2d69d7, roughness: .58, metalness: 0 }),
  vessel: new THREE.MeshStandardMaterial({ color: 0xc7464e, roughness: .6, metalness: 0 }),
  nerve: new THREE.MeshStandardMaterial({ color: 0xe6b916, roughness: .58, metalness: 0 }),
  neural: new THREE.MeshStandardMaterial({ color: 0xcaa77b, roughness: .74, metalness: 0 }),
  reference: new THREE.MeshStandardMaterial({ color: 0xd9d0bf, roughness: .76, metalness: 0, transparent: true, opacity: .34, depthWrite: false })
};

const HIGHLIGHTS = {
  muscle: new THREE.MeshStandardMaterial({ color: 0xff6a2c, emissive: 0xb52c08, emissiveIntensity: .9, roughness: .45 }),
  bone: new THREE.MeshStandardMaterial({ color: 0x3e7cff, emissive: 0x1247cd, emissiveIntensity: 1.1, roughness: .42 }),
  ligament: new THREE.MeshStandardMaterial({ color: 0x9d55ff, emissive: 0x5d1fc0, emissiveIntensity: 1.0, roughness: .42 }),
  vessel: new THREE.MeshStandardMaterial({ color: 0xff3944, emissive: 0xb40d19, emissiveIntensity: 1.05, roughness: .42 }),
  nerve: new THREE.MeshStandardMaterial({ color: 0xffd91f, emissive: 0xa86f00, emissiveIntensity: 1.15, roughness: .42 })
};

function requestRender() {
  if (!renderHandle) renderHandle = requestAnimationFrame(() => {
    renderHandle = 0;
    if (renderer && scene && camera) renderer.render(scene, camera);
  });
}

function initThree() {
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x030914);
  camera = new THREE.PerspectiveCamera(31, 1, 0.01, 1000);
  renderer = new THREE.WebGLRenderer({
    canvas,
    antialias: !LOW_POWER,
    alpha: false,
    powerPreference: 'high-performance',
    preserveDrawingBuffer: false,
    precision: LOW_POWER ? 'mediump' : 'highp'
  });
  renderer.setPixelRatio(IS_COMPACT ? 1 : Math.min(devicePixelRatio || 1, 1.5));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.12;

  controls = new OrbitControls(camera, canvas);
  controls.enableDamping = false;
  controls.enablePan = false;
  controls.zoomToCursor = true;
  controls.minDistance = .2;
  controls.maxDistance = 14;
  controls.addEventListener('change', requestRender);

  scene.add(new THREE.HemisphereLight(0xeaf3ff, 0x19100e, 2.1));
  const key = new THREE.DirectionalLight(0xffffff, 2.7);
  key.position.set(4, 7, 6);
  scene.add(key);
  const fill = new THREE.DirectionalLight(0x89a9ff, 1.05);
  fill.position.set(-5, 2, 3);
  scene.add(fill);
  const rim = new THREE.DirectionalLight(0x4e78bd, .75);
  rim.position.set(-4, 4, -5);
  scene.add(rim);

  raycaster = new THREE.Raycaster();
  pointer = new THREE.Vector2();
  resize();
  addEventListener('resize', resize, { passive: true });
  canvas.addEventListener('pointerup', handlePick);
  document.addEventListener('visibilitychange', () => { if (document.hidden) stopAutoRotate(); });
  requestRender();
}

function resize() {
  if (!renderer || !viewer) return;
  const rect = viewer.getBoundingClientRect();
  renderer.setSize(Math.max(1, rect.width), Math.max(1, rect.height), false);
  camera.aspect = Math.max(.2, rect.width / Math.max(1, rect.height));
  camera.updateProjectionMatrix();
  requestRender();
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

function disposeMaterial(material) {
  if (Array.isArray(material)) material.forEach(disposeMaterial);
  else if (material && !Object.values(MATERIALS).includes(material) && !Object.values(HIGHLIGHTS).includes(material)) material.dispose?.();
}

function materialFor(name, system) {
  if (system === 'muscle') return /tendon|aponeuros|fascia/i.test(name) ? MATERIALS.tendon : MATERIALS.muscle;
  if (system === 'bone') return MATERIALS.bone;
  if (system === 'ligament') return MATERIALS.ligament;
  if (system === 'vessel') {
    if (/vein|vena|venous|saphen/i.test(name)) return MATERIALS.vein;
    if (/arter|aorta|coronar/i.test(name)) return MATERIALS.artery;
    return MATERIALS.vessel;
  }
  if (system === 'nerve') return /brain|cerebr|spinal cord|medulla/i.test(name) ? MATERIALS.neural : MATERIALS.nerve;
  return MATERIALS.bone;
}

function prepRoot(root, system) {
  root.traverse(object => {
    if (!object.isMesh) return;
    object.castShadow = false;
    object.receiveShadow = false;
    object.frustumCulled = true;
    object.userData.system = system;
    object.userData.displayName = prettyName(object.name);
    disposeMaterial(object.material);
    object.material = materialFor(object.userData.displayName, system);
    object.userData.baseMaterial = object.material;
  });
  root.updateMatrixWorld(true);
}

function prepReference(root) {
  root.traverse(object => {
    if (!object.isMesh) return;
    object.castShadow = false;
    object.receiveShadow = false;
    disposeMaterial(object.material);
    object.material = MATERIALS.reference;
  });
  root.updateMatrixWorld(true);
}

function disposeRoot(root) {
  root?.traverse(object => {
    if (!object.isMesh) return;
    object.geometry?.dispose?.();
    disposeMaterial(object.material);
  });
}

async function switchSystem(system, initial = false) {
  if (!SYSTEMS[system]) return;
  const sequence = ++loadSequence;
  stopAutoRotate();
  activeSystem = system;
  app.dataset.system = system;
  const config = SYSTEMS[system];
  systemSubtitle.textContent = config.title;
  browserHeading.textContent = config.title;
  structureSearch.placeholder = config.placeholder;
  structureSearch.value = '';
  previewIcon.textContent = config.icon;
  document.querySelectorAll('.system-btn').forEach(button => button.classList.toggle('active', button.dataset.system === system));
  renderTabs();
  restoreSelection();
  layersIsolated = false;
  transparencyEnabled = false;
  document.getElementById('layersBtn').classList.remove('active');
  document.getElementById('transparencyBtn').classList.remove('active');

  if (activeRoot) { scene.remove(activeRoot); disposeRoot(activeRoot); activeRoot = null; }
  if (referenceRoot) { scene.remove(referenceRoot); disposeRoot(referenceRoot); referenceRoot = null; }
  activeMeshes = [];
  renderStructureList([]);
  loading.innerHTML = '<div class="spinner"></div><span>3D anatomi yükleniyor…</span>';
  loading.classList.remove('hidden');
  modelLabel.classList.add('hidden');
  requestRender();

  try {
    const wantsReference = REFERENCE_SYSTEMS.has(system);
    const [root, reference] = await Promise.all([
      loadModel(MODEL_FILES[system]),
      wantsReference ? loadModel(REFERENCE_MODEL).catch(() => null) : Promise.resolve(null)
    ]);
    if (sequence !== loadSequence) {
      disposeRoot(root);
      disposeRoot(reference);
      return;
    }
    prepRoot(root, system);
    activeRoot = root;
    scene.add(root);
    if (reference) {
      prepReference(reference);
      referenceRoot = reference;
      scene.add(reference);
    }
    activeMeshes = collectEligible(root);
    loading.classList.add('hidden');
    fitWholeBody();
    renderStructureList(activeMeshes);

    const preferred = preferredMeshFor(system) || activeMeshes[0];
    if (preferred) selectMesh(preferred, false);
    if (!initial) viewer.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    requestRender();
  } catch (error) {
    console.error(error);
    if (sequence === loadSequence) loading.innerHTML = '<span>3D model yüklenemedi.</span>';
  }
}

function collectEligible(root) {
  const meshes = [];
  root.traverse(object => {
    if (!object.isMesh) return;
    const name = prettyName(object.name);
    if (!name || name.length < 2 || name.length > 100 || /collection|default|material/i.test(name)) return;
    meshes.push(object);
  });
  return meshes;
}

function prettyName(raw = '') {
  return String(raw)
    .replace(/_/g, ' ')
    .replace(/(?:\.?(?:00\d|0\d\d|\d\d\d))$/i, '')
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

function preferredMeshFor(system) {
  if (system === 'muscle') return findMesh(/biceps\s*brachii/i);
  if (system === 'bone') return findMesh(/^fibula(?:\s|$)/i);
  if (system === 'ligament') return findMesh(/anterior\s+talofibular|talofibular\s+anterior|atfl/i);
  if (system === 'vessel') return findMesh(/anterior\s+tibial\s+arter/i);
  if (system === 'nerve') return findMesh(/median\s+nerve|medianus/i);
  return null;
}

function restoreSelection() {
  if (selectedMesh?.isMesh) selectedMesh.material = selectedMesh.userData.baseMaterial || materialFor(prettyName(selectedMesh.name), activeSystem);
  selectedMesh = null;
}

function selectMesh(mesh, shouldFocus = false) {
  if (!mesh?.isMesh) return;
  restoreSelection();
  selectedMesh = mesh;
  mesh.visible = true;
  mesh.material = HIGHLIGHTS[activeSystem];
  currentTab = 'general';
  renderTabs();
  updateInfo();
  updateListSelection();
  applyLayerState();
  if (shouldFocus) focusMesh(mesh);
  requestRender();
}

function renderTabs() {
  const config = TAB_CONFIG[activeSystem] || TAB_CONFIG.muscle;
  tabs.replaceChildren(...config.map(([key, label]) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = `tab${key === currentTab ? ' active' : ''}`;
    button.dataset.tab = key;
    button.textContent = label;
    button.setAttribute('role', 'tab');
    button.setAttribute('aria-selected', String(key === currentTab));
    button.addEventListener('click', () => {
      currentTab = key;
      tabs.querySelectorAll('.tab').forEach(item => {
        const active = item.dataset.tab === key;
        item.classList.toggle('active', active);
        item.setAttribute('aria-selected', String(active));
      });
      updateInfo();
    });
    return button;
  }));
}

function updateInfo() {
  if (!selectedMesh) return;
  const name = prettyName(selectedMesh.name) || 'Anatomik yapı';
  const info = getInfo(name, activeSystem);
  structureName.textContent = info.title || name;
  structureSubtitle.textContent = info.subtitle;
  structureSystem.textContent = SYSTEMS[activeSystem].badge;
  structureText.textContent = info[currentTab] || info.general;
  modelLabelText.textContent = info.title || name;
  modelLabel.classList.remove('hidden');
  renderFacts(info.facts || genericFacts(name, activeSystem));
}

function renderFacts(facts) {
  const safeFacts = Array.isArray(facts) ? facts.slice(0, 4) : [];
  factGrid.replaceChildren(...safeFacts.map(([label, value]) => {
    const card = document.createElement('div');
    card.className = 'fact-card';
    const heading = document.createElement('b');
    heading.textContent = label;
    const text = document.createElement('span');
    text.textContent = value;
    card.append(heading, text);
    return card;
  }));
}

function getInfo(name, system) {
  const special = SPECIAL_INFO.find(item => item.system === system && item.match.test(name));
  if (special) return special.info;
  const key = normalizeName(name);
  const entry = metadata?.[system]?.[key] || metadata?.[system]?.[name] || null;
  const fallback = fallbackInfo(name, system);
  return entry ? { ...fallback, ...entry, title: entry.tr || entry.title || entry.name || name } : fallback;
}

function fallbackInfo(name, system) {
  if (system === 'bone') return {
    title: name, subtitle: 'İskelet sistemi yapısı',
    general: `${name}, iskelet sistemine ait anatomik bir yapıdır. Üç boyutlu model üzerinden konumu, komşulukları ve yüzey özellikleri incelenebilir.`,
    features: 'Kemiklerin yüz, kenar, çıkıntı, oluk ve foraminaları yapının anatomik bölgesine göre değerlendirilir.',
    articulations: 'Eklemleşme ilişkileri komşu kemikler ve eklem yüzleri üzerinden değerlendirilir.',
    attachments: 'Kas, tendon ve ligament tutunmaları kemiğin ilgili anatomik yüzeylerine göre incelenir.',
    clinical: 'Klinik önem; kırık paterni, eklem ilişkisi, nörovasküler komşuluk ve fonksiyonel etkilenimle birlikte değerlendirilir.'
  };
  if (system === 'ligament') return {
    title: name, subtitle: 'Ligament yapısı',
    general: `${name}, kemik veya eklem yapıları arasında pasif stabiliteye katkı sağlayan fibröz bağ dokusu yapısıdır.`,
    attachments: 'Başlangıç ve tutunma noktaları ligamentin bağladığı kemik yüzeylerine göre değerlendirilir.',
    connections: 'Ligamentin komşu kapsül, kemik ve diğer bağlarla ilişkisi eklem stabilitesinin anlaşılmasında önemlidir.',
    function: 'Aşırı eklem hareketlerini sınırlar ve pasif mekanik stabiliteye katkı sağlar.',
    clinical: 'Yaralanma mekanizması, lokal hassasiyet, instabilite testleri ve görüntüleme bulguları birlikte değerlendirilir.'
  };
  if (system === 'vessel') return {
    title: name, subtitle: 'Damar sistemi yapısı',
    general: `${name}, dolaşım sistemine ait bir damar yapısıdır. Anatomik değerlendirmede başlangıç, seyir, dallanma ve beslediği ya da drene ettiği bölge birlikte incelenir.`,
    origin: 'Damarın başlangıcı, bağlı olduğu proksimal arter veya venöz ağ ile birlikte değerlendirilir.',
    course: 'Seyir; komşu kas, kemik, sinir ve fasya yapılarıyla anatomik ilişkisi üzerinden tanımlanır.',
    branches: 'Dallanma veya birleşme paterni anatomik varyasyon gösterebilir ve ilgili bölgenin damar ağıyla birlikte değerlendirilir.',
    supply: 'Arterlerde beslenen doku alanı, venlerde ise drene edilen bölge esas alınır.',
    clinical: 'Nabız, perfüzyon, kanama, tromboz ve cerrahi girişim açısından nörovasküler komşuluklar klinik önem taşır.'
  };
  if (system === 'nerve') return {
    title: name, subtitle: 'Sinir sistemi yapısı',
    general: `${name}, sinir sistemine ait anatomik bir yapıdır. Kökleri, seyri, dalları ve motor-duyusal dağılımı birlikte değerlendirilir.`,
    anatomy: 'Anatomik organizasyon santral ve periferik bağlantılar ile segmental kök katkıları üzerinden incelenir.',
    course: 'Sinirin seyri komşu kas, damar, kemik ve fasiyal tünellerle ilişkisi üzerinden değerlendirilir.',
    branches: 'Dalların dağılımı hedef kaslar, eklemler ve kutanöz alanlarla birlikte incelenir.',
    innervation: 'Motor, duyusal ve gerektiğinde otonom liflerin hedef dokulara dağılımı değerlendirilir.',
    function: 'Motor kontrol, duyu iletimi ve proprioseptif geri bildirimde ilgili yapıya göre rol üstlenir.',
    clinical: 'Kompresyon, gerilme ve travmatik yaralanmalarda lezyon seviyesi motor ve duyusal bulgularla lokalize edilir.'
  };
  return {
    title: name, subtitle: 'Kas sistemi yapısı',
    general: `${name}, kas sistemi içinde hareket ve eklem kontrolüne katkı sağlayan anatomik bir yapıdır.`,
    origin: 'Origo, kasın görece daha sabit başlangıç tutunma alanıdır.',
    insertion: 'Insertio, kasın görece daha hareketli sonlanma tutunma alanıdır.',
    innervation: 'Kasın motor kontrolü ilgili periferik sinir ve segmental kökler üzerinden sağlanır.',
    function: 'Fonksiyon; lif yönü, eklem ekseni, kas uzunluğu ve sinerjist-antagonist ilişkileriyle birlikte değerlendirilir.'
  };
}

function genericFacts(name, system) {
  if (system === 'muscle') return [['Tip', 'İskelet kası'], ['Yapı', name], ['Değerlendirme', 'Origo / Insertio'], ['Kontrol', 'Periferik motor sinir']];
  if (system === 'bone') return [['Tip', 'Kemik'], ['Yapı', name], ['İnceleme', 'Yüzey / Eklem'], ['Klinik', 'Komşuluklar']];
  if (system === 'ligament') return [['Tip', 'Fibröz bağ'], ['Yapı', name], ['Rol', 'Pasif stabilite'], ['İnceleme', 'Tutunma noktaları']];
  if (system === 'vessel') return [['Tip', /vein|vena/i.test(name) ? 'Ven' : 'Damar'], ['Yapı', name], ['İnceleme', 'Seyir / Dallar'], ['Klinik', 'Perfüzyon / Drenaj']];
  return [['Tip', 'Sinir yapısı'], ['Yapı', name], ['İnceleme', 'Seyir / Dallar'], ['Klinik', 'Motor / Duyusal']];
}

function renderStructureList(meshes, query = '') {
  const normalizedQuery = query.trim().toLocaleLowerCase('tr-TR');
  const rows = meshes
    .map(mesh => ({ mesh, name: prettyName(mesh.name) }))
    .filter(row => !normalizedQuery || row.name.toLocaleLowerCase('tr-TR').includes(normalizedQuery))
    .sort((a, b) => a.name.localeCompare(b.name, 'en'))
    .slice(0, normalizedQuery ? 60 : 36);

  structureList.replaceChildren(...rows.map(({ mesh, name }) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = `structure-item${mesh === selectedMesh ? ' active' : ''}`;
    button.textContent = getInfo(name, activeSystem).title || name;
    button.dataset.meshName = mesh.uuid;
    button.setAttribute('role', 'option');
    button.setAttribute('aria-selected', String(mesh === selectedMesh));
    button.addEventListener('click', () => selectMesh(mesh, false));
    return button;
  }));
}

function updateListSelection() {
  structureList.querySelectorAll('.structure-item').forEach(button => {
    const active = button.dataset.meshName === selectedMesh?.uuid;
    button.classList.toggle('active', active);
    button.setAttribute('aria-selected', String(active));
  });
}

function handlePick(event) {
  if (!activeRoot || !loading.classList.contains('hidden')) return;
  const rect = canvas.getBoundingClientRect();
  pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
  pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
  raycaster.setFromCamera(pointer, camera);
  const candidates = activeMeshes.filter(mesh => mesh.visible);
  const hit = raycaster.intersectObjects(candidates, false)[0];
  if (hit?.object) selectMesh(hit.object, false);
}

function combinedBounds() {
  const box = new THREE.Box3();
  if (activeRoot) box.expandByObject(activeRoot);
  if (referenceRoot) box.expandByObject(referenceRoot);
  return box;
}

function fitWholeBody() {
  const box = combinedBounds();
  if (box.isEmpty()) return;
  const size = box.getSize(new THREE.Vector3());
  const center = box.getCenter(new THREE.Vector3());
  const maxDim = Math.max(size.x, size.y, size.z, .1);
  controls.target.copy(center.clone().add(new THREE.Vector3(0, size.y * .02, 0)));
  const side = IS_COMPACT ? .56 : .72;
  const depth = IS_COMPACT ? 1.95 : 1.72;
  camera.position.set(center.x + maxDim * side, center.y + size.y * .03, center.z + maxDim * depth);
  camera.near = Math.max(.002, maxDim / 220);
  camera.far = maxDim * 40;
  controls.minDistance = Math.max(.16, maxDim * .08);
  controls.maxDistance = maxDim * 8;
  camera.updateProjectionMatrix();
  controls.update();
  requestRender();
}

function focusMesh(mesh) {
  const box = new THREE.Box3().setFromObject(mesh);
  if (box.isEmpty()) return;
  const size = box.getSize(new THREE.Vector3());
  const center = box.getCenter(new THREE.Vector3());
  const maxDim = Math.max(size.x, size.y, size.z, .08);
  controls.target.copy(center);
  camera.position.copy(center).add(new THREE.Vector3(1.0, .25, 1.5).normalize().multiplyScalar(maxDim * 2.2 + .4));
  camera.near = Math.max(.002, maxDim / 150);
  camera.far = Math.max(40, maxDim * 80);
  camera.updateProjectionMatrix();
  controls.update();
  requestRender();
}

function zoom(multiplier) {
  const direction = camera.position.clone().sub(controls.target);
  const next = direction.length() * multiplier;
  const limited = THREE.MathUtils.clamp(next, controls.minDistance, controls.maxDistance);
  camera.position.copy(controls.target).add(direction.normalize().multiplyScalar(limited));
  controls.update();
  requestRender();
}

function rotateStep() {
  if (!activeRoot) return;
  activeRoot.rotation.y += Math.PI / 8;
  if (referenceRoot) referenceRoot.rotation.y += Math.PI / 8;
  activeRoot.updateMatrixWorld(true);
  referenceRoot?.updateMatrixWorld(true);
  requestRender();
}

function autoRotateTick() {
  if (!autoRotate || !activeRoot || document.hidden) { autoRotateHandle = 0; return; }
  activeRoot.rotation.y += .008;
  if (referenceRoot) referenceRoot.rotation.y += .008;
  activeRoot.updateMatrixWorld(true);
  referenceRoot?.updateMatrixWorld(true);
  requestRender();
  autoRotateHandle = requestAnimationFrame(autoRotateTick);
}

function toggleAutoRotate() {
  autoRotate = !autoRotate;
  const button = document.getElementById('autoRotateBtn');
  button.classList.toggle('active', autoRotate);
  button.setAttribute('aria-pressed', String(autoRotate));
  button.querySelector('b').textContent = autoRotate ? 'Ⅱ' : '▷';
  if (autoRotate && !autoRotateHandle) autoRotateHandle = requestAnimationFrame(autoRotateTick);
  if (!autoRotate) stopAutoRotate();
}

function stopAutoRotate() {
  autoRotate = false;
  if (autoRotateHandle) cancelAnimationFrame(autoRotateHandle);
  autoRotateHandle = 0;
  const button = document.getElementById('autoRotateBtn');
  if (button) {
    button.classList.remove('active');
    button.setAttribute('aria-pressed', 'false');
    const icon = button.querySelector('b');
    if (icon) icon.textContent = '▷';
  }
}

function applyLayerState() {
  activeMeshes.forEach(mesh => {
    const isSelected = mesh === selectedMesh;
    mesh.visible = !layersIsolated || isSelected;
    if (isSelected) mesh.material = HIGHLIGHTS[activeSystem];
    else if (transparencyEnabled) {
      const base = mesh.userData.baseMaterial || materialFor(prettyName(mesh.name), activeSystem);
      const transparent = base.clone();
      transparent.transparent = true;
      transparent.opacity = .18;
      transparent.depthWrite = false;
      mesh.material = transparent;
    } else {
      if (mesh.material && mesh.material !== mesh.userData.baseMaterial) disposeMaterial(mesh.material);
      mesh.material = mesh.userData.baseMaterial || materialFor(prettyName(mesh.name), activeSystem);
    }
  });
  if (referenceRoot) referenceRoot.visible = !layersIsolated;
  activeRoot?.updateMatrixWorld(true);
  requestRender();
}

function toggleLayers() {
  if (!selectedMesh) return;
  layersIsolated = !layersIsolated;
  document.getElementById('layersBtn').classList.toggle('active', layersIsolated);
  applyLayerState();
}

function toggleTransparency() {
  transparencyEnabled = !transparencyEnabled;
  document.getElementById('transparencyBtn').classList.toggle('active', transparencyEnabled);
  applyLayerState();
}

function toggleFocusMode() {
  app.classList.toggle('focus-mode');
  requestAnimationFrame(() => { resize(); fitWholeBody(); });
}

function bindUi() {
  document.querySelectorAll('.system-btn').forEach(button => button.addEventListener('click', () => switchSystem(button.dataset.system)));
  document.getElementById('rotateBtn').addEventListener('click', rotateStep);
  document.getElementById('zoomInBtn').addEventListener('click', () => zoom(.8));
  document.getElementById('zoomOutBtn').addEventListener('click', () => zoom(1.25));
  document.getElementById('resetBtn').addEventListener('click', fitWholeBody);
  document.getElementById('autoRotateBtn').addEventListener('click', toggleAutoRotate);
  document.getElementById('layersBtn').addEventListener('click', toggleLayers);
  document.getElementById('transparencyBtn').addEventListener('click', toggleTransparency);
  document.getElementById('focusModeBtn').addEventListener('click', toggleFocusMode);
  document.getElementById('backBtn').addEventListener('click', () => history.back());
  structureSearch.addEventListener('input', () => renderStructureList(activeMeshes, structureSearch.value));
}

async function init() {
  app.dataset.system = 'muscle';
  bindUi();
  renderTabs();
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
        selectedHighlighted: Boolean(selectedMesh && selectedMesh.material === HIGHLIGHTS[activeSystem]),
        cameraDistance: camera && controls ? camera.position.distanceTo(controls.target) : null,
        pixelRatio: renderer?.getPixelRatio?.() || null,
        continuousAnimation: autoRotate,
        activeRotationY: activeRoot?.rotation?.y || 0,
        referenceLoaded: Boolean(referenceRoot),
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
