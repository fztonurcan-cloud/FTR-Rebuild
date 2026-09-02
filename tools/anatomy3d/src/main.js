const BASE = import.meta.env.BASE_URL || './';
const QA_MODE = new URLSearchParams(location.search).get('qa') === '1';

const SYSTEMS = {
  muscle: { label: 'Kaslar', title: 'KAS SİSTEMİ', badge: 'KAS', placeholder: 'Kas ara...', icon: '◒', accent: [151, 66, 255] },
  bone: { label: 'Kemikler', title: 'KEMİK SİSTEMİ', badge: 'KEMİK', placeholder: 'Kemik ara...', icon: '◇', accent: [55, 101, 255] },
  ligament: { label: 'Ligamentler', title: 'LİGAMENT SİSTEMİ', badge: 'LİGAMENT', placeholder: 'Ligament ara...', icon: '✦', accent: [151, 66, 255] },
  vessel: { label: 'Damarlar', title: 'DAMAR SİSTEMİ', badge: 'DAMAR', placeholder: 'Damar ara...', icon: '◉', accent: [224, 46, 58] },
  nerve: { label: 'Sinirler', title: 'SİNİR SİSTEMİ', badge: 'SİNİR', placeholder: 'Sinir ara...', icon: '☀', accent: [255, 210, 0] }
};

const TAB_CONFIG = {
  muscle: [['general', 'Genel Bilgi'], ['origin', 'Origo'], ['insertion', 'Insertio'], ['innervation', 'İnnervasyon'], ['function', 'Fonksiyon']],
  bone: [['general', 'Genel Bilgi'], ['features', 'Anatomik Özellikler'], ['articulations', 'Eklemleşmeler'], ['attachments', 'Kas - Ligament Tutunmaları'], ['clinical', 'Klinik Önemi']],
  ligament: [['general', 'Genel Bilgi'], ['attachments', 'Başlangıç - Tutunma'], ['connections', 'Bağladığı Yapılar'], ['function', 'Fonksiyon'], ['clinical', 'Klinik Önemi']],
  vessel: [['general', 'Genel Bilgi'], ['origin', 'Başlangıç'], ['course', 'Seyir'], ['branches', 'Dalları'], ['supply', 'Beslediği Bölge'], ['clinical', 'Klinik Önemi']],
  nerve: [['general', 'Genel Bilgi'], ['anatomy', 'Anatomi'], ['course', 'Seyir'], ['branches', 'Dalları'], ['innervation', 'İnnervasyon'], ['function', 'Fonksiyon'], ['clinical', 'Klinik Önemi']]
};

const SPECIAL_INFO = [
  {
    system: 'muscle', match: /biceps\s*brachii/i,
    info: {
      title: 'Biceps brachii', subtitle: 'İki başlı kol kası',
      general: 'Biceps brachii, ön kolun supinasyonunda ve dirsek ekleminde fleksiyonda önemli rol alan iki başlı bir kastır. Uzun ve kısa başları skapuladan başlar ve ortak tendonla radiusa tutunur.',
      origin: 'Caput longum: tuberculum supraglenoidale scapulae. Caput breve: processus coracoideus scapulae.',
      insertion: 'Tuberositas radii ve aponeurosis bicipitalis.',
      innervation: 'N. musculocutaneus (C5–C6; C7 katkısı bulunabilir).',
      function: 'Ön kol supinasyonu ve dirsek fleksiyonu; omuz fleksiyonuna yardımcı olur.',
      facts: [['Tip', 'İskelet kası'], ['Bölge', 'Üst kol (Anterior)'], ['Kanlanma', 'A. brachialis dalları'], ['Sinir', 'N. musculocutaneus']]
    }
  },
  {
    system: 'bone', match: /^fibula(?:\s|$)/i,
    info: {
      title: 'Fibula (Kamış kemiği)', subtitle: 'Alt ekstremite kemiği',
      general: 'Fibula, bacağın lateralinde yer alan ince ve uzun kemiktir. Tibia ile birlikte alt bacağın stabilitesine katkı sağlar ve vücut ağırlığının küçük bir bölümünü taşır.',
      features: 'Baş, boyun ve gövdeden oluşur; distal ucu lateral malleolü meydana getirir. Fibula boynu n. fibularis communis ile yakın komşuluktadır.',
      articulations: 'Proksimalde tibia ile proksimal tibiofibular eklemde, distalde tibia ile distal tibiofibular sindesmozda ilişkilidir. Lateral malleol talusla ayak bileği eklemine katılır.',
      attachments: 'Biceps femoris tendonu ve lig. collaterale fibulare fibula başına tutunur. Birçok alt bacak kası fibuladan köken veya tutunma alır.',
      clinical: 'Fibula boynu kırıkları n. fibularis communis yaralanması açısından önemlidir. Lateral malleol kırıkları ayak bileği stabilitesini etkileyebilir.',
      facts: [['Tip', 'Uzun kemik'], ['Bölge', 'Alt bacak (Lateral)'], ['Eklem', 'Tibiofibular ilişkiler'], ['Klinik komşuluk', 'N. fibularis communis']]
    }
  },
  {
    system: 'ligament', match: /anterior\s+talofibular|talofibular\s+anterior|atfl/i,
    info: {
      title: 'Anterior talofibular ligament (ATFL)', subtitle: 'Dış yan bağ (Ayak bileği)',
      general: 'Anterior talofibular ligament, ayak bileğinin lateral bağ kompleksinin en sık yaralanan bileşenidir ve özellikle plantar fleksiyon ile inversiyon sırasında lateral stabiliteye katkı sağlar.',
      attachments: 'Fibulanın lateral malleolünün ön kenarından talusun boyun bölgesinin lateral yüzüne uzanır.',
      connections: 'Fibula ile talusu bağlar; calcaneofibular ve posterior talofibular ligamentlerle birlikte lateral bağ kompleksini oluşturur.',
      function: 'Talusun öne translasyonunu ve aşırı inversiyonu sınırlar; ayak bileğinin lateral pasif stabilitesine katkı sağlar.',
      clinical: 'İnversiyon tipi ayak bileği burkulmalarında sık etkilenir. Anterior drawer testi ATFL bütünlüğünün klinik değerlendirmesinde kullanılır.',
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
      branches: 'Ön kolda kas dalları ve n. interosseus anterior; elde rekürren tenar dal ile palmar ve dijital dallar verir.',
      innervation: 'Ön kol fleksör-pronator grubunun çoğu, tenar kasların önemli bölümü ve lateral iki lumbrikal kas; elde lateral palmar bölgenin duyusuna katkı sağlar.',
      function: 'El bileği ve parmak fleksiyonu, pronasyon, başparmak opponens hareketi ve elde duyusal geri bildirime katkı sağlar.',
      clinical: 'Karpal tünel sendromu median sinirin sık görülen kompresyon tablolarındandır; tenar güçsüzlük ve median sinir dağılımında parestezi görülebilir.',
      facts: [['Tip', 'Karma sinir'], ['Kök', 'C5–T1'], ['Seyir', 'Kol → Ön kol → Karpal tünel → El'], ['Klinik', 'Karpal tünel ilişkisi']]
    }
  }
];

const app = document.getElementById('anatomy-app');
const canvas = document.getElementById('anatomyCanvas');
const ctx = canvas.getContext('2d', { alpha: false, desynchronized: true });
const viewer = document.getElementById('viewer');
const loading = document.getElementById('loading');
const systemSubtitle = document.getElementById('systemSubtitle');
const browserHeading = document.getElementById('browserHeading');
const structureSearch = document.getElementById('structureSearch');
const structureList = document.getElementById('structureList');
const structureName = document.getElementById('structureName');
const structureSubtitle = document.getElementById('structureSubtitle');
const structureText = document.getElementById('structureText');
const structureSystem = document.getElementById('structureSystem');
const tabs = document.getElementById('tabs');
const factGrid = document.getElementById('factGrid');
const modelLabel = document.getElementById('modelLabel');
const modelLabelText = document.getElementById('modelLabelText');
const previewVisual = document.getElementById('previewVisual');
const previewIcon = document.getElementById('previewIcon');

const idCanvas = document.createElement('canvas');
const idCtx = idCanvas.getContext('2d', { willReadFrequently: true });
const maskCanvas = document.createElement('canvas');
const maskCtx = maskCanvas.getContext('2d');
const selectedCanvas = document.createElement('canvas');
const selectedCtx = selectedCanvas.getContext('2d');

let atlas = null;
let activeSystem = 'muscle';
let systemData = null;
let activeStructures = [];
let selectedStructure = null;
let beautyImage = null;
let idImage = null;
let idPixels = null;
let currentTab = 'general';
let imageSequence = 0;
let view = { scale: 1, x: 0, y: 0 };
let pointerStart = null;
let pointerMoved = false;
const pointers = new Map();
let pinchStart = null;
let renderQueued = false;
let highlightReadyFor = null;

function loadImage(src) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.decoding = 'async';
    image.onload = () => resolve(image);
    image.onerror = reject;
    image.src = src;
  });
}

function clamp(value, min, max) { return Math.max(min, Math.min(max, value)); }
function normalizeName(value) { return String(value || '').toLocaleLowerCase('en-US').replace(/[^a-z0-9]+/g, ' ').trim(); }

function preferredRegex(system) {
  if (system === 'muscle') return /biceps\s*brachii/i;
  if (system === 'bone') return /^fibula(?:\s|$)/i;
  if (system === 'ligament') return /anterior\s+talofibular|talofibular\s+anterior|atfl/i;
  if (system === 'vessel') return /anterior\s+tibial\s+arter/i;
  if (system === 'nerve') return /median\s+nerve|medianus/i;
  return /.*/;
}

function dedupeStructures(rows) {
  const seen = new Set();
  return rows.filter(row => {
    const key = normalizeName(row.name);
    if (!key || seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function categoryFor(name, system) {
  const n = name.toLowerCase();
  if (system === 'muscle') {
    if (/deltoid|biceps|triceps|brach|forearm|flexor|extensor.*carp|pronator|supinator/.test(n)) return 'ÜST EKSTREMİTE';
    if (/glute|quadr|hamstring|biceps femor|semitend|semimembr|gastro|soleus|tibial|fibular|perone|adductor|sartorius/.test(n)) return 'ALT EKSTREMİTE';
    return 'GÖVDE';
  }
  if (system === 'bone') {
    if (/skull|cranium|mandible|maxilla|vertebr|rib|sternum|sacrum/.test(n)) return 'AKSİYAL İSKELET';
    if (/clav|scap|humer|radius|ulna|carpal|metacarp|hand|phalange/.test(n)) return 'ÜST EKSTREMİTE';
    return 'ALT EKSTREMİTE';
  }
  if (system === 'nerve') return /brain|cerebr|spinal cord|medulla/.test(n) ? 'SANTRAL SİNİR SİSTEMİ' : 'PERİFERİK SİNİRLER';
  return 'BÖLGELER / YAPILAR';
}

function orderedStructures(rows, system) {
  const categoryOrder = system === 'muscle' ? ['ÜST EKSTREMİTE', 'GÖVDE', 'ALT EKSTREMİTE']
    : system === 'bone' ? ['AKSİYAL İSKELET', 'ÜST EKSTREMİTE', 'ALT EKSTREMİTE']
      : system === 'nerve' ? ['SANTRAL SİNİR SİSTEMİ', 'PERİFERİK SİNİRLER'] : ['BÖLGELER / YAPILAR'];
  return [...rows].sort((a, b) => {
    const ai = categoryOrder.indexOf(categoryFor(a.name, system));
    const bi = categoryOrder.indexOf(categoryFor(b.name, system));
    return (ai - bi) || a.name.localeCompare(b.name, 'tr');
  });
}

function renderStructureList(rows = activeStructures) {
  structureList.replaceChildren();
  let lastCategory = '';
  for (const row of orderedStructures(rows, activeSystem)) {
    const category = categoryFor(row.name, activeSystem);
    if (category !== lastCategory) {
      const heading = document.createElement('div');
      heading.className = 'structure-group';
      heading.textContent = category;
      structureList.appendChild(heading);
      lastCategory = category;
    }
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'structure-row';
    button.dataset.id = String(row.id);
    button.setAttribute('role', 'option');
    button.innerHTML = '<span class="structure-dot"></span><span class="structure-label"></span>';
    button.querySelector('.structure-label').textContent = row.name;
    button.addEventListener('click', () => selectStructure(row, true));
    structureList.appendChild(button);
  }
  updateListSelection();
}

function updateListSelection() {
  structureList.querySelectorAll('.structure-row').forEach(button => {
    const active = selectedStructure && Number(button.dataset.id) === Number(selectedStructure.id);
    button.classList.toggle('active', Boolean(active));
    button.setAttribute('aria-selected', String(Boolean(active)));
  });
  const active = structureList.querySelector('.structure-row.active');
  active?.scrollIntoView({ block: 'nearest' });
}

function renderTabs() {
  const config = TAB_CONFIG[activeSystem];
  tabs.replaceChildren(...config.map(([key, label]) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = `tab${currentTab === key ? ' active' : ''}`;
    button.dataset.tab = key;
    button.textContent = label;
    button.setAttribute('role', 'tab');
    button.setAttribute('aria-selected', String(currentTab === key));
    button.addEventListener('click', () => {
      currentTab = key;
      renderTabs();
      updateInfo();
    });
    return button;
  }));
}

function fallbackInfo(name, system) {
  const titles = {
    muscle: 'Kas sistemi yapısı', bone: 'Kemik sistemi yapısı', ligament: 'Ligament sistemi yapısı',
    vessel: 'Damar sistemi yapısı', nerve: 'Sinir sistemi yapısı'
  };
  return {
    title: name,
    subtitle: titles[system],
    general: 'Bu yapı atlas üzerinde doğru konumuyla gösterilir. Ayrıntılı akademik metin yalnız kaynak doğrulaması tamamlandıktan sonra yayınlanacaktır.',
    origin: 'Doğrulanmış içerik hazırlanıyor.', insertion: 'Doğrulanmış içerik hazırlanıyor.', innervation: 'Doğrulanmış içerik hazırlanıyor.', function: 'Doğrulanmış içerik hazırlanıyor.',
    features: 'Doğrulanmış içerik hazırlanıyor.', articulations: 'Doğrulanmış içerik hazırlanıyor.', attachments: 'Doğrulanmış içerik hazırlanıyor.', clinical: 'Doğrulanmış içerik hazırlanıyor.',
    connections: 'Doğrulanmış içerik hazırlanıyor.', course: 'Doğrulanmış içerik hazırlanıyor.', branches: 'Doğrulanmış içerik hazırlanıyor.', supply: 'Doğrulanmış içerik hazırlanıyor.', anatomy: 'Doğrulanmış içerik hazırlanıyor.',
    facts: [['Durum', 'Atlas konumu hazır'], ['İçerik', 'Akademik doğrulama bekliyor']]
  };
}

function infoFor(structure) {
  const special = SPECIAL_INFO.find(item => item.system === activeSystem && item.match.test(structure.name));
  return special?.info || fallbackInfo(structure.name, activeSystem);
}

function updateInfo() {
  if (!selectedStructure) return;
  const info = infoFor(selectedStructure);
  structureName.textContent = info.title || selectedStructure.name;
  structureSubtitle.textContent = info.subtitle || '';
  structureSystem.textContent = SYSTEMS[activeSystem].badge;
  structureText.textContent = info[currentTab] || info.general;
  modelLabelText.textContent = info.title || selectedStructure.name;
  factGrid.replaceChildren(...(info.facts || []).slice(0, 5).map(([label, value]) => {
    const card = document.createElement('div');
    card.className = 'fact-card';
    const b = document.createElement('b'); b.textContent = label;
    const span = document.createElement('span'); span.textContent = value;
    card.append(b, span);
    return card;
  }));
  updatePreview(info);
  updateModelLabel();
}

function updatePreview() {
  if (!beautyImage || !selectedStructure) return;
  const anchor = selectedStructure.anchor || [.5, .5];
  previewVisual.style.backgroundImage = `url("${beautyImage.src}")`;
  previewVisual.style.backgroundSize = '360% auto';
  previewVisual.style.backgroundPosition = `${anchor[0] * 100}% ${anchor[1] * 100}%`;
  previewIcon.textContent = '';
}

function updateModelLabel() {
  if (!selectedStructure?.anchor) { modelLabel.classList.add('hidden'); return; }
  const [ax, ay] = selectedStructure.anchor;
  const px = (ax * canvas.width * view.scale + view.x) / canvas.width;
  const py = (ay * canvas.height * view.scale + view.y) / canvas.height;
  modelLabel.style.left = `${clamp(px * 100, 12, 88)}%`;
  modelLabel.style.top = `${clamp(py * 100, 8, 92)}%`;
  modelLabel.classList.remove('hidden');
}

function queueDraw() {
  if (renderQueued) return;
  renderQueued = true;
  requestAnimationFrame(() => { renderQueued = false; draw(); });
}

function buildHighlightMask() {
  if (!idPixels || !selectedStructure || !beautyImage) return;
  const key = `${activeSystem}:${selectedStructure.id}`;
  if (highlightReadyFor === key) return;
  const [tr, tg, tb] = selectedStructure.rgb;
  const w = idCanvas.width, h = idCanvas.height;
  const out = maskCtx.createImageData(w, h);
  const src = idPixels.data, dst = out.data;
  const [hr, hg, hb] = SYSTEMS[activeSystem].accent;
  for (let i = 0; i < src.length; i += 4) {
    const delta = Math.abs(src[i] - tr) + Math.abs(src[i + 1] - tg) + Math.abs(src[i + 2] - tb);
    if (delta <= 10) {
      dst[i] = hr; dst[i + 1] = hg; dst[i + 2] = hb; dst[i + 3] = 255;
    }
  }
  maskCtx.putImageData(out, 0, 0);

  selectedCtx.clearRect(0, 0, w, h);
  selectedCtx.globalCompositeOperation = 'source-over';
  selectedCtx.drawImage(beautyImage, 0, 0, w, h);
  selectedCtx.globalCompositeOperation = 'destination-in';
  selectedCtx.drawImage(maskCanvas, 0, 0);
  selectedCtx.globalCompositeOperation = 'source-over';
  highlightReadyFor = key;
}

function draw() {
  const w = canvas.width, h = canvas.height;
  ctx.save();
  ctx.fillStyle = '#030914';
  ctx.fillRect(0, 0, w, h);
  if (!beautyImage) { ctx.restore(); return; }
  buildHighlightMask();
  ctx.translate(view.x, view.y);
  ctx.scale(view.scale, view.scale);
  ctx.globalAlpha = selectedStructure ? .54 : 1;
  ctx.drawImage(beautyImage, 0, 0, w, h);
  ctx.globalAlpha = 1;
  if (selectedStructure && highlightReadyFor) {
    ctx.save();
    ctx.globalAlpha = .85;
    ctx.filter = 'blur(10px)';
    ctx.drawImage(maskCanvas, 0, 0);
    ctx.restore();
    ctx.drawImage(selectedCanvas, 0, 0);
    ctx.globalAlpha = .48;
    ctx.drawImage(maskCanvas, 0, 0);
    ctx.globalAlpha = 1;
  }
  ctx.restore();
  updateModelLabel();
}

function selectStructure(structure, fromList = false) {
  if (!structure) return;
  selectedStructure = structure;
  currentTab = 'general';
  highlightReadyFor = null;
  renderTabs();
  updateInfo();
  updateListSelection();
  queueDraw();
  if (fromList && matchMedia('(max-width: 760px)').matches) viewer.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
}

function imagePointFromEvent(event) {
  const rect = canvas.getBoundingClientRect();
  const canvasX = (event.clientX - rect.left) * (canvas.width / rect.width);
  const canvasY = (event.clientY - rect.top) * (canvas.height / rect.height);
  return [(canvasX - view.x) / view.scale, (canvasY - view.y) / view.scale];
}

function pickAt(event) {
  if (!idPixels || !systemData) return;
  const [x, y] = imagePointFromEvent(event);
  if (x < 0 || y < 0 || x >= idCanvas.width || y >= idCanvas.height) return;
  const ix = Math.floor(x), iy = Math.floor(y);
  const index = (iy * idCanvas.width + ix) * 4;
  const rgb = [idPixels.data[index], idPixels.data[index + 1], idPixels.data[index + 2]];
  let picked = systemData.structures.find(row => row.rgb[0] === rgb[0] && row.rgb[1] === rgb[1] && row.rgb[2] === rgb[2]);
  if (!picked) {
    let best = null, bestDelta = 18;
    for (const row of systemData.structures) {
      const delta = Math.abs(row.rgb[0] - rgb[0]) + Math.abs(row.rgb[1] - rgb[1]) + Math.abs(row.rgb[2] - rgb[2]);
      if (delta < bestDelta) { bestDelta = delta; best = row; }
    }
    picked = best;
  }
  if (picked) selectStructure(picked, false);
}

function clampView() {
  if (view.scale <= 1.001) { view.scale = 1; view.x = 0; view.y = 0; return; }
  const minX = canvas.width * (1 - view.scale);
  const minY = canvas.height * (1 - view.scale);
  view.x = clamp(view.x, minX, 0);
  view.y = clamp(view.y, minY, 0);
}

function setZoom(scale, centerX = canvas.width / 2, centerY = canvas.height / 2) {
  const old = view.scale;
  const next = clamp(scale, 1, 3.2);
  const imageX = (centerX - view.x) / old;
  const imageY = (centerY - view.y) / old;
  view.scale = next;
  view.x = centerX - imageX * next;
  view.y = centerY - imageY * next;
  clampView();
  queueDraw();
}

function pointerCanvasPoint(event) {
  const rect = canvas.getBoundingClientRect();
  return {
    x: (event.clientX - rect.left) * canvas.width / rect.width,
    y: (event.clientY - rect.top) * canvas.height / rect.height
  };
}

canvas.addEventListener('pointerdown', event => {
  canvas.setPointerCapture?.(event.pointerId);
  const p = pointerCanvasPoint(event);
  pointers.set(event.pointerId, p);
  pointerStart = { ...p, clientX: event.clientX, clientY: event.clientY };
  pointerMoved = false;
  if (pointers.size === 2) {
    const [a, b] = [...pointers.values()];
    pinchStart = { distance: Math.hypot(a.x - b.x, a.y - b.y), scale: view.scale, center: { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 } };
  }
});

canvas.addEventListener('pointermove', event => {
  if (!pointers.has(event.pointerId)) return;
  const previous = pointers.get(event.pointerId);
  const current = pointerCanvasPoint(event);
  pointers.set(event.pointerId, current);
  if (pointers.size === 2 && pinchStart) {
    const [a, b] = [...pointers.values()];
    const distance = Math.max(1, Math.hypot(a.x - b.x, a.y - b.y));
    setZoom(pinchStart.scale * distance / Math.max(1, pinchStart.distance), pinchStart.center.x, pinchStart.center.y);
    pointerMoved = true;
    return;
  }
  if (view.scale > 1 && pointers.size === 1) {
    const dx = current.x - previous.x, dy = current.y - previous.y;
    if (Math.hypot(dx, dy) > 1) {
      view.x += dx; view.y += dy; clampView(); queueDraw(); pointerMoved = true;
    }
  }
  if (pointerStart && Math.hypot(event.clientX - pointerStart.clientX, event.clientY - pointerStart.clientY) > 8) pointerMoved = true;
});

canvas.addEventListener('pointerup', event => {
  if (!pointerMoved && pointers.size === 1) pickAt(event);
  pointers.delete(event.pointerId);
  if (pointers.size < 2) pinchStart = null;
  pointerStart = null;
});
canvas.addEventListener('pointercancel', event => { pointers.delete(event.pointerId); pinchStart = null; pointerStart = null; });
canvas.addEventListener('dblclick', event => {
  const p = pointerCanvasPoint(event);
  setZoom(view.scale > 1 ? 1 : 2, p.x, p.y);
});

async function switchSystem(system) {
  if (!atlas?.systems?.[system]) return;
  const sequence = ++imageSequence;
  activeSystem = system;
  systemData = atlas.systems[system];
  app.dataset.system = system;
  const config = SYSTEMS[system];
  systemSubtitle.textContent = config.title;
  browserHeading.textContent = config.title;
  structureSearch.placeholder = config.placeholder;
  structureSearch.value = '';
  previewIcon.textContent = config.icon;
  document.querySelectorAll('.system-btn').forEach(button => button.classList.toggle('active', button.dataset.system === system));
  loading.classList.remove('hidden');
  loading.querySelector('span').textContent = `${config.title} yükleniyor…`;
  modelLabel.classList.add('hidden');
  selectedStructure = null;
  highlightReadyFor = null;
  view = { scale: 1, x: 0, y: 0 };
  currentTab = 'general';
  renderTabs();

  try {
    const [beauty, ids] = await Promise.all([
      loadImage(`${BASE}${systemData.beauty}`),
      loadImage(`${BASE}${systemData.id_map}`)
    ]);
    if (sequence !== imageSequence) return;
    beautyImage = beauty;
    idImage = ids;
    canvas.width = atlas.width || beauty.naturalWidth;
    canvas.height = atlas.height || beauty.naturalHeight;
    idCanvas.width = canvas.width; idCanvas.height = canvas.height;
    maskCanvas.width = canvas.width; maskCanvas.height = canvas.height;
    selectedCanvas.width = canvas.width; selectedCanvas.height = canvas.height;
    idCtx.clearRect(0, 0, idCanvas.width, idCanvas.height);
    idCtx.drawImage(idImage, 0, 0, idCanvas.width, idCanvas.height);
    idPixels = idCtx.getImageData(0, 0, idCanvas.width, idCanvas.height);
    activeStructures = dedupeStructures(systemData.structures || []);
    renderStructureList(activeStructures);
    const preferred = systemData.structures.find(row => preferredRegex(system).test(row.name)) || activeStructures[0];
    loading.classList.add('hidden');
    if (preferred) selectStructure(preferred, false);
    else queueDraw();
  } catch (error) {
    console.error(error);
    loading.innerHTML = '<span>Anatomi atlası yüklenemedi.</span>';
  }
}

structureSearch.addEventListener('input', () => {
  const q = normalizeName(structureSearch.value);
  renderStructureList(!q ? activeStructures : activeStructures.filter(row => normalizeName(row.name).includes(q)));
});

document.querySelectorAll('.system-btn').forEach(button => button.addEventListener('click', () => switchSystem(button.dataset.system)));

document.getElementById('backBtn').addEventListener('click', () => {
  if (history.length > 1) history.back(); else location.href = '../index.html';
});

document.getElementById('focusModeBtn').addEventListener('click', async () => {
  try {
    if (!document.fullscreenElement) await app.requestFullscreen?.();
    else await document.exitFullscreen?.();
  } catch (_) { /* WebView fullscreen may be unavailable. */ }
});

addEventListener('resize', queueDraw, { passive: true });

function qaState() {
  return {
    renderMode: 'static-layered-atlas',
    webgl: false,
    activeSystem,
    activeStructureCount: systemData?.structures?.length || 0,
    activeMeshCount: 0,
    selectedStructure: selectedStructure?.name || '',
    selectedHighlighted: Boolean(selectedStructure && highlightReadyFor),
    continuousAnimation: false,
    pixelRatio: 1,
    runtime3dModels: false,
    imageReady: Boolean(beautyImage && idPixels),
    zoomScale: view.scale
  };
}

window.__FTR_ANATOMY_QA__ = {
  state: qaState,
  pick(pattern) {
    const regex = new RegExp(pattern, 'i');
    const row = systemData?.structures?.find(item => regex.test(item.name));
    if (row) selectStructure(row, false);
    return qaState();
  },
  zoom(scale) { setZoom(scale); return qaState(); },
  resetView() { view = { scale: 1, x: 0, y: 0 }; queueDraw(); return qaState(); }
};

async function boot() {
  try {
    const response = await fetch(`${BASE}data/atlas-map.json`, { cache: 'no-store' });
    if (!response.ok) throw new Error(`atlas-map ${response.status}`);
    atlas = await response.json();
    if (atlas.render_mode !== 'static-layered-atlas' || atlas.policy?.webgl !== false) throw new Error('Static atlas policy missing');
    await switchSystem('muscle');
    document.documentElement.dataset.qaReady = 'true';
  } catch (error) {
    console.error(error);
    loading.innerHTML = '<span>Anatomi atlası başlatılamadı.</span>';
    if (QA_MODE) document.documentElement.dataset.qaReady = 'true';
  }
}

boot();
