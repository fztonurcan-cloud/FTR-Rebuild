(() => {
  'use strict';
  const db = window.FTR_CLINICAL_SCALES;
  if (!db) throw new Error('Clinical scales data missing');

  const $ = id => document.getElementById(id);
  const views = [...document.querySelectorAll('.view')];
  const categoryList = $('categoryList');
  const categoryScales = $('categoryScales');
  const searchResults = $('searchResults');
  const searchInput = $('searchInput');
  const resultSummary = $('resultSummary');
  const detailBody = $('detailBody');
  const actionArea = $('actionArea');
  const assessmentBody = $('assessmentBody');
  const assessmentActions = $('assessmentActions');
  const favBtn = $('favBtn');

  let currentCategory = null;
  let currentScale = null;
  let currentTab = 'about';
  let assessmentState = {};
  const favoriteKey = 'ftr-clinical-favorites-v1';
  const recentKey = 'ftr-clinical-recent-v1';
  const favorites = new Set(readArray(favoriteKey));

  const BERG = [
    'Oturmadan ayağa kalkma','Desteksiz ayakta durma','Desteksiz oturma','Ayakta durmadan oturma',
    'Transfer','Gözler kapalı ayakta durma','Ayaklar bitişik ayakta durma','Öne uzanma',
    'Yerden nesne alma','Arkaya bakmak için dönme','360° dönme','Basamağa dönüşümlü ayak koyma',
    'Tandem duruş','Tek ayak üzerinde durma'
  ];

  // Locked 16-item / 28-point POMA: balance 9 items = 16, gait 7 items = 12.
  // "Step length and height" is one gait item with four binary observations
  // (right length, right clearance, left length, left clearance), hence max 4.
  const TINETTI = [
    {label:'Oturma dengesi', max:1, section:'Denge'},
    {label:'Ayağa kalkma', max:2, section:'Denge'},
    {label:'Ayağa kalkma denemeleri', max:2, section:'Denge'},
    {label:'İlk ayakta duruş dengesi', max:2, section:'Denge'},
    {label:'Ayakta duruş dengesi', max:2, section:'Denge'},
    {label:'Hafif itmeye yanıt', max:2, section:'Denge'},
    {label:'Gözler kapalı denge', max:1, section:'Denge'},
    {label:'360° dönme', max:2, section:'Denge'},
    {label:'Oturma', max:2, section:'Denge'},
    {label:'Yürüyüş başlatma', max:1, section:'Yürüyüş'},
    {label:'Adım uzunluğu ve yüksekliği — sağ/sol dört gözlem toplamı', max:4, section:'Yürüyüş'},
    {label:'Adım simetrisi', max:1, section:'Yürüyüş'},
    {label:'Adım devamlılığı', max:1, section:'Yürüyüş'},
    {label:'Yürüme yolu', max:2, section:'Yürüyüş'},
    {label:'Gövde', max:2, section:'Yürüyüş'},
    {label:'Yürüme tabanı', max:1, section:'Yürüyüş'}
  ];

  const DGI = [
    'Düz zeminde yürüme','Yürüme hızını değiştirme','Yatay baş hareketleriyle yürüme',
    'Dikey baş hareketleriyle yürüme','Yürürken pivot dönüş','Engelin üzerinden geçme',
    'Engelin etrafından geçme','Merdiven'
  ];

  function readArray(key) {
    try {
      const value = JSON.parse(localStorage.getItem(key) || '[]');
      return Array.isArray(value) ? value : [];
    } catch {
      return [];
    }
  }
  function writeArray(key, values) {
    try { localStorage.setItem(key, JSON.stringify(values)); } catch {}
  }
  function setView(id) {
    views.forEach(view => view.classList.toggle('active', view.id === id));
    window.scrollTo(0, 0);
  }
  function categoryById(id) { return db.categories.find(item => item.id === id); }
  function scaleById(id) { return db.scales.find(item => item.id === id); }
  function scalesForCategory(id) { return db.scales.filter(item => item.category === id); }
  function goHome() { location.href = '../index.html'; }

  function validateAssessmentContracts() {
    const tinettiBalance = TINETTI.filter(x => x.section === 'Denge').reduce((a,x) => a + x.max, 0);
    const tinettiGait = TINETTI.filter(x => x.section === 'Yürüyüş').reduce((a,x) => a + x.max, 0);
    const tinettiTotal = TINETTI.reduce((a,x) => a + x.max, 0);
    if (BERG.length !== 14 || BERG.length * 4 !== 56) throw new Error('Berg 14-item/56-point contract failed');
    if (DGI.length !== 8 || DGI.length * 3 !== 24) throw new Error('DGI 8-item/24-point contract failed');
    if (TINETTI.length !== 16 || tinettiBalance !== 16 || tinettiGait !== 12 || tinettiTotal !== 28) {
      throw new Error(`Tinetti POMA contract failed: balance=${tinettiBalance}, gait=${tinettiGait}, total=${tinettiTotal}`);
    }
    const expectedMax = {berg:56, tinetti:28, dgi:24};
    for (const [id,max] of Object.entries(expectedMax)) {
      const scale = scaleById(id);
      if (!scale?.interactive || Number(scale.interactive.max) !== max) throw new Error(`${id} interactive max contract failed`);
    }
  }

  function iconSvg(name) {
    const common = 'viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"';
    const paths = {
      activity:'<circle cx="24" cy="8" r="4"/><path d="M18 17h12l3 11-6 3-3-8-4 8-7-3 5-11Zm6 14v10m-7 0 7-10 7 10"/>',
      brain:'<path d="M20 8c-6-3-11 2-9 8-5 2-5 9 0 11-2 7 5 11 10 7m7-26c6-3 11 2 9 8 5 2 5 9 0 11 2 7-5 11-10 7M24 7v31"/>',
      wave:'<path d="M5 26h7l4-13 7 25 6-19 4 7h10"/>',
      balance:'<circle cx="24" cy="8" r="4"/><path d="M24 12v13m0-8-11 8m11-8 11 8M24 25l-8 15m8-15 8 15M8 40h32"/>',
      joint:'<path d="M17 6c6 5 7 10 6 17m8-17c-6 5-7 10-6 17M19 42c5-6 6-12 4-19m6 19c-5-6-6-12-4-19M20 21h8m-8 6h8"/>',
      child:'<circle cx="24" cy="9" r="5"/><path d="M24 14v13m0-7-10 5m10-5 10 5M24 27l-9 13m9-13 9 13"/>',
      hand:'<path d="M13 25V13c0-4 5-4 5 0v8-12c0-4 5-4 5 0v12V8c0-4 5-4 5 0v13-10c0-4 5-4 5 0v15l3-5c2-3 7 0 5 4l-6 13c-2 4-6 6-11 6-8 0-13-7-14-14l-1-5c-1-4 4-5 6 0l2 5"/>',
      heart:'<path d="M24 41S6 30 6 17c0-9 11-12 18-4 7-8 18-5 18 4 0 13-18 24-18 24Z"/><path d="M12 25h7l3-7 5 14 3-7h6"/>'
    };
    return `<svg ${common}>${paths[name] || paths.activity}</svg>`;
  }

  // Lightweight immediate fallback; visual-enhancer.js replaces this with the
  // instrument-specific original offline clinical illustration on the same tick.
  function scene() {
    return '<svg viewBox="0 0 180 150" role="img" aria-label="Klinik değerlendirme görseli"><rect x="1" y="1" width="178" height="148" rx="18" fill="#071522" stroke="#173a52"/><circle cx="90" cy="38" r="13" fill="none" stroke="#dce9f2" stroke-width="3"/><path d="M90 51v43M90 63 65 79m25-16 25 16M90 94 73 125m17-31 17 31" fill="none" stroke="#dce9f2" stroke-width="3" stroke-linecap="round"/><path d="M29 128h122" stroke="#43c7ff" stroke-width="3" stroke-linecap="round"/></svg>';
  }

  function registerRecent(id) {
    const rows = readArray(recentKey).filter(value => value !== id);
    rows.unshift(id);
    writeArray(recentKey, rows.slice(0, 8));
  }
  function updateFavButton() {
    const enabled = !!currentScale;
    favBtn.disabled = !enabled;
    favBtn.textContent = enabled && favorites.has(currentScale.id) ? '★' : '☆';
    favBtn.setAttribute('aria-label', enabled && favorites.has(currentScale?.id) ? 'Favorilerden çıkar' : 'Favoriye ekle');
  }
  function toggleFavorite() {
    if (!currentScale) return;
    if (favorites.has(currentScale.id)) favorites.delete(currentScale.id); else favorites.add(currentScale.id);
    writeArray(favoriteKey, [...favorites]);
    updateFavButton();
  }

  function categoryButton(category) {
    const rows = scalesForCategory(category.id);
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'category-card';
    button.style.setProperty('--card-accent', category.accent);
    button.innerHTML = `<span class="card-icon">${iconSvg(category.icon)}</span><span class="card-copy"><strong>${category.title}</strong><small>${rows.map(s=>s.short).join(' • ')}</small></span><span class="card-count"><small>${rows.length}</small><b>›</b></span>`;
    button.addEventListener('click', () => openCategory(category.id, true));
    return button;
  }
  function scaleButton(scale) {
    const category = categoryById(scale.category);
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'scale-card';
    button.style.setProperty('--card-accent', category.accent);
    button.innerHTML = `<span class="card-icon">${iconSvg(category.icon)}</span><span class="card-copy"><strong>${scale.name}</strong><small>${scale.short} • ${scale.purpose}</small></span><span class="card-count"><span class="license-dot ${scale.rights.mode==='open'?'':'restricted'}"></span><b>›</b></span>`;
    button.addEventListener('click', () => openScale(scale.id, true));
    return button;
  }
  function renderCatalog() {
    categoryList.replaceChildren(...db.categories.map(categoryButton));
    resultSummary.textContent = `${db.categories.length} kategori • ${db.scales.length} klinik değerlendirme aracı`;
  }
  function renderScaleList(target, rows) {
    target.replaceChildren(...rows.map(scaleButton));
    if (!rows.length) {
      const empty = document.createElement('div');
      empty.className = 'empty-state';
      empty.textContent = 'Bu filtrede ölçek bulunamadı.';
      target.append(empty);
    }
  }

  function openCatalog(push=false) {
    currentCategory = null;
    currentScale = null;
    updateFavButton();
    searchInput.value = '';
    searchResults.classList.add('hidden');
    categoryList.classList.remove('hidden');
    renderCatalog();
    setView('catalogView');
    if (push) history.pushState({view:'catalog'}, '');
  }
  function openCategory(id, push=false) {
    const category = categoryById(id);
    if (!category) return;
    currentCategory = id;
    currentScale = null;
    $('categoryTitle').textContent = category.title;
    const rows = scalesForCategory(id);
    $('categorySubtitle').textContent = `${rows.length} klinik değerlendirme aracı`;
    renderScaleList(categoryScales, rows);
    updateFavButton();
    setView('categoryView');
    if (push) history.pushState({view:'category', id}, '');
  }
  function openScale(id, push=false) {
    const scale = scaleById(id);
    if (!scale) return;
    currentScale = scale;
    currentCategory = scale.category;
    currentTab = 'about';
    registerRecent(id);
    $('scaleVisual').innerHTML = scene();
    $('scaleShort').textContent = scale.short;
    $('scaleTitle').textContent = scale.name;
    $('rightsChip').textContent = scale.rights.label;
    $('durationChip').textContent = scale.duration;
    updateFavButton();
    renderTabs();
    renderDetail();
    setView('detailView');
    if (push) history.pushState({view:'detail', id}, '');
  }

  function renderTabs() {
    document.querySelectorAll('#detailTabs button').forEach(button => button.classList.toggle('active', button.dataset.tab === currentTab));
  }
  function bullet(items) { return `<ul>${items.map(item => `<li>${item}</li>`).join('')}</ul>`; }
  function renderDetail() {
    const s = currentScale;
    if (!s) return;
    let html = '';
    if (currentTab === 'about') html = `<h2>Ne ölçer?</h2><p>${s.purpose}</p><div class="info-grid"><div class="info-cell"><b>Hedef grup</b><span>${s.population}</span></div><div class="info-cell"><b>Süre</b><span>${s.duration}</span></div><div class="info-cell"><b>Ekipman</b><span>${s.equipment}</span></div><div class="info-cell"><b>Türkçe kanıt</b><span>${s.turkish}</span></div></div><h2 style="margin-top:17px">Değerlendirme alanları</h2>${bullet(s.domains)}`;
    if (currentTab === 'apply') html = `<h2>Uygulama çerçevesi</h2><p>${s.format}</p><p><b>Hedef popülasyon:</b> ${s.population}</p><p><b>Gerekli ekipman:</b> ${s.equipment}</p><p><b>Tahmini süre:</b> ${s.duration}</p><div class="rights-box ${s.rights.mode==='open'?'open':''}"><b>${s.rights.label}</b><br>${s.rights.note}</div>`;
    if (currentTab === 'score') html = `<h2>Puanlama</h2><p>${s.format}</p>${s.interactive?'<p>Bu araç için FTR Akademi içinde kaynak sözleşmesine uygun interaktif kayıt/puanlama kullanılabilir.</p>':'<p>Bu ölçekte lisans veya resmi form koşulları nedeniyle FTR Akademi tam madde metnini yeniden üretmez. Puanlama prensibi eğitimsel olarak açıklanır.</p>'}`;
    if (currentTab === 'interpret') html = `<h2>Klinik yorumlama</h2><p>${s.interpretation}</p><p><b>Türkçe kullanım:</b> ${s.turkish}</p><div class="rights-box ${s.rights.mode==='open'?'open':''}">Sonuç tek başına tanı veya tedavi kararı değildir. Ölçeğin validasyon popülasyonu ve standardize protokolü dikkate alınmalıdır.</div>`;
    if (currentTab === 'sources') html = `<h2>Kaynaklar ve hak durumu</h2><div class="source-list">${s.sources.map(([label,url])=>`<a href="${url}" target="_blank" rel="noopener">${label}<br><small>${url}</small></a>`).join('')}</div><div class="rights-box ${s.rights.mode==='open'?'open':''}"><b>${s.rights.label}</b><br>${s.rights.note}</div>`;
    detailBody.innerHTML = html;
    renderActionArea();
  }
  function renderActionArea() {
    const s = currentScale;
    if (!s) return;
    if (s.interactive) {
      actionArea.innerHTML = '<button id="startAssessment" class="primary" type="button">Değerlendirmeyi Başlat</button>';
      $('startAssessment').addEventListener('click', () => openAssessment(true));
    } else {
      actionArea.innerHTML = '<div class="disabled-note"><b>Güvenli uygulama modu:</b> Bu ölçeğin telif/lisans veya resmi form koşulu netleşmeden tam anket maddeleri FTR Akademi içine kopyalanmayacaktır. Eğitimsel bilgiler ve resmi kaynaklar kullanılabilir.</div>';
    }
  }

  function openAssessment(push=false) {
    const s = currentScale;
    if (!s?.interactive) return;
    assessmentState = {};
    $('assessmentShort').textContent = s.short;
    $('assessmentTitle').textContent = s.name;
    $('assessmentProgress').textContent = 'Kaynak sözleşmesine uygun klinik kayıt';
    renderAssessment();
    setView('assessmentView');
    if (push) history.pushState({view:'assessment', id:s.id}, '');
  }
  function setAssessmentValue(key, value, button, scope) {
    assessmentState[key] = value;
    if (button) {
      scope.querySelectorAll(`[data-key="${CSS.escape(key)}"]`).forEach(item => item.classList.remove('selected'));
      button.classList.add('selected');
    }
  }
  function optionButtons(key, options) {
    return `<div class="option-grid">${options.map(value => `<button class="score-option" type="button" data-key="${key}" data-value="${value}">${value}</button>`).join('')}</div>`;
  }
  function scoredItems(items, maxFn) {
    return items.map((item,index) => {
      const label = typeof item === 'string' ? item : item.label;
      const max = typeof maxFn === 'function' ? maxFn(index) : maxFn;
      const section = typeof item === 'string' || !item.section ? '' : `<span class="eyebrow">${item.section}</span>`;
      return `<section class="assessment-card">${section}<h2>${index+1}. ${label}</h2><p>Yalnız puanı seçin; standardize uygulama ve puan anchor’larını “Uygulama / Puanlama” bölümündeki kaynakla birlikte kontrol edin.</p>${optionButtons(`i${index}`, Array.from({length:max+1},(_,value)=>value))}</section>`;
    }).join('');
  }
  function renderAssessment() {
    const s = currentScale;
    let html = '';
    const actions = '<button id="cancelAssessment" type="button">İptal</button><button id="finishAssessment" class="primary" type="button">Sonucu Hesapla</button>';
    switch (s.interactive.kind) {
      case 'mas':
        html = `<section class="assessment-card"><h2>Kas tonusu derecesi</h2><p>Değerlendirilen kas/eklem, taraf ve uygulama hızını klinik notunuzda kaydedin.</p>${optionButtons('grade',s.interactive.options)}</section>`;
        break;
      case 'tardieu':
        html = `<section class="assessment-card"><h2>R1 / R2 açıları</h2><p>R2: V1’de tam pasif hareket; R1: hızlı V3’te yakalama/klonus açısı. Aynı eklem açı konvansiyonunu kullanın.</p><div class="field-grid"><div class="field"><label>R1 (°)</label><input data-field="r1" type="number" min="-180" max="180" step="1"></div><div class="field"><label>R2 (°)</label><input data-field="r2" type="number" min="-180" max="180" step="1"></div></div></section><section class="assessment-card"><h2>Kas reaksiyon kalitesi</h2><p>Modified Tardieu 0–5 kas reaksiyon kalitesi derecesi.</p>${optionButtons('quality',['0','1','2','3','4','5'])}</section>`;
        break;
      case 'penn':
        html = `<section class="assessment-card"><h2>Spazm sıklığı</h2><p>0–4 sıklık derecesi.</p>${optionButtons('frequency',['0','1','2','3','4'])}</section><section class="assessment-card"><h2>Spazm şiddeti</h2><p>Sıklık 0 ise şiddet bölümü uygulanmaz.</p>${optionButtons('severity',['1','2','3'])}</section>`;
        break;
      case 'berg': html = scoredItems(BERG,4); break;
      case 'time':
        html = `<section class="assessment-card"><h2>TUG süresi</h2><p>Sandalyeden kalk → 3 m yürü → dön → geri yürü → otur.</p><div class="field"><label>Süre (saniye)</label><input data-field="time" type="number" min="0" max="600" step="0.01" inputmode="decimal"></div></section><section class="assessment-card"><h2>Yardımcı cihaz</h2><div class="field"><select data-field="device"><option value="Yok">Yok</option><option value="Baston">Baston</option><option value="Walker">Walker</option><option value="Diğer">Diğer</option></select></div></section>`;
        break;
      case 'tinetti': html = scoredItems(TINETTI,index => TINETTI[index].max); break;
      case 'dgi': html = scoredItems(DGI,3); break;
      case 'hand-time':
        html = `<section class="assessment-card"><h2>9-HPT zaman kaydı</h2><p>Standart 9-HPT fiziksel kit/protokolü ile ölçtüğünüz süreyi kaydedin; uygulama vendor norm tablolarını içermez.</p><div class="field-grid"><div class="field"><label>El</label><select data-field="hand"><option>Sağ</option><option>Sol</option></select></div><div class="field"><label>Süre (sn)</label><input data-field="time" type="number" min="0" max="600" step="0.01"></div></div></section>`;
        break;
      case '6mwt':
        html = `<section class="assessment-card"><h2>6 dakika yürüme kaydı</h2><div class="field-grid"><div class="field"><label>Toplam mesafe (m)</label><input data-field="distance" type="number" min="0" max="3000" step="1"></div><div class="field"><label>Parkur uzunluğu (m)</label><input data-field="walkway" type="number" min="5" max="100" step="1" value="30"></div><div class="field"><label>Dinlenme sayısı</label><input data-field="rests" type="number" min="0" max="50" step="1" value="0"></div><div class="field"><label>Yardımcı cihaz</label><select data-field="device"><option>Yok</option><option>Baston</option><option>Walker</option><option>Diğer</option></select></div></div></section><section class="assessment-card"><h2>Standardizasyon hatırlatması</h2><p>Dinlenme sırasında kronometre devam eder. Seri takipte aynı parkur ve yardımcı cihazı mümkün olduğunca koruyun.</p></section>`;
        break;
      default: throw new Error(`Unsupported interactive kind: ${s.interactive.kind}`);
    }
    assessmentBody.innerHTML = html;
    assessmentActions.innerHTML = actions;
    assessmentBody.querySelectorAll('.score-option').forEach(button => button.addEventListener('click', () => setAssessmentValue(button.dataset.key, button.dataset.value, button, button.closest('.assessment-card'))));
    assessmentBody.querySelectorAll('[data-field]').forEach(input => input.addEventListener('input', () => { assessmentState[input.dataset.field] = input.value; }));
    $('cancelAssessment').addEventListener('click', () => history.back());
    $('finishAssessment').addEventListener('click', finishAssessment);
  }

  function numericInput(name) {
    const raw = assessmentState[name];
    const value = Number(raw);
    return raw == null || raw === '' || !Number.isFinite(value) ? null : value;
  }
  function finishAssessment() {
    const s = currentScale;
    let value = '';
    let note = '';
    let meta = [];
    const missing = message => { alert(message); return false; };

    if (s.interactive.kind === 'mas') {
      if (assessmentState.grade == null) return missing('MAS derecesini seçin.');
      value = `MAS ${assessmentState.grade}`;
      note = 'Derece pasif harekete karşı artmış tonusu tanımlar; hız bağımlı spastisite özelliklerini tek başına temsil etmez.';
    }
    if (s.interactive.kind === 'tardieu') {
      const r1 = numericInput('r1');
      const r2 = numericInput('r2');
      if (r1 == null || r2 == null || assessmentState.quality == null) return missing('R1, R2 ve reaksiyon kalitesini girin.');
      value = `R1 ${r1.toFixed(0)}° • R2 ${r2.toFixed(0)}°`;
      note = 'R1/R2 yalnız aynı kas-eklem, pozisyon, hız tanımı ve açı yönü kullanıldığında birlikte yorumlanmalıdır. Aritmetik fark otomatik bir tanı değildir.';
      meta = [`Aritmetik R2−R1: ${(r2-r1).toFixed(0)}°`, `Reaksiyon: ${assessmentState.quality}/5`];
    }
    if (s.interactive.kind === 'penn') {
      if (assessmentState.frequency == null) return missing('Spazm sıklığını seçin.');
      if (assessmentState.frequency !== '0' && assessmentState.severity == null) return missing('Spazm şiddetini seçin.');
      value = `Sıklık ${assessmentState.frequency}/4`;
      note = assessmentState.frequency === '0' ? 'Spazm bildirilmedi; şiddet bölümü uygulanmaz.' : 'Sıklık ve şiddet birlikte kaydedilir; skor hasta bildirimidir.';
      if (assessmentState.severity) meta = [`Şiddet: ${assessmentState.severity}/3`];
    }
    if (['berg','dgi','tinetti'].includes(s.interactive.kind)) {
      const items = s.interactive.kind === 'berg' ? BERG : s.interactive.kind === 'dgi' ? DGI : TINETTI;
      let total = 0;
      for (let index=0; index<items.length; index++) {
        if (assessmentState[`i${index}`] == null) return missing(`Tüm ${items.length} maddeleri puanlayın.`);
        total += Number(assessmentState[`i${index}`]);
      }
      const expectedMax = s.interactive.kind === 'berg' ? 56 : s.interactive.kind === 'dgi' ? 24 : 28;
      if (Number(s.interactive.max) !== expectedMax || total < 0 || total > expectedMax) throw new Error(`${s.id} score contract violation`);
      value = `${total} / ${expectedMax}`;
      if (s.interactive.kind === 'berg') note = 'Yüksek skor daha iyi denge performansını gösterir. Düşme riski cut-off’ları tanı ve popülasyona göre değişir; tek evrensel eşik kullanılmaz.';
      if (s.interactive.kind === 'dgi') note = 'Yüksek skor daha iyi dinamik yürüme dengesini gösterir; cut-off ve değişim eşikleri ilgili tanı/popülasyon kaynağıyla yorumlanmalıdır.';
      if (s.interactive.kind === 'tinetti') {
        const balance = TINETTI.slice(0,9).reduce((sum,_,index) => sum + Number(assessmentState[`i${index}`]), 0);
        const gait = TINETTI.slice(9).reduce((sum,_,index) => sum + Number(assessmentState[`i${index+9}`]), 0);
        if (balance > 16 || gait > 12 || balance + gait !== total) throw new Error('Tinetti subscale score contract violation');
        meta = [`Denge: ${balance} / 16`, `Yürüyüş: ${gait} / 12`, 'Sürüm: 16 madde / 28 puan POMA'];
        note = 'Yüksek skor daha iyi denge-yürüyüş performansını gösterir. Düşme riski sınıfları yalnız kullanılan POMA sürümü ve doğrulandığı popülasyon bağlamında yorumlanmalıdır.';
      }
    }
    if (s.interactive.kind === 'time') {
      const time = numericInput('time');
      if (time == null || time < 0) return missing('Geçerli süreyi girin.');
      value = `${time.toFixed(2)} sn`;
      note = 'Daha kısa süre genellikle daha iyi fonksiyonel mobiliteyi gösterir. Tek bir evrensel düşme-risk eşiği yoktur.';
      meta = [`Yardımcı cihaz: ${assessmentState.device || 'Yok'}`];
    }
    if (s.interactive.kind === 'hand-time') {
      const time = numericInput('time');
      if (time == null || time < 0) return missing('Geçerli süreyi girin.');
      value = `${time.toFixed(2)} sn`;
      note = 'Daha kısa süre daha iyi parmak becerisini gösterir. Yaş, test edilen el, dominantlık, standardize pano ve kullanılan norm seti belirtilmeden otomatik normal/anormal sınıfı üretilmez.';
      meta = [`El: ${assessmentState.hand || 'Sağ'}`, 'Standart fiziksel kit gereklidir'];
    }
    if (s.interactive.kind === '6mwt') {
      const distance = numericInput('distance');
      const walkway = numericInput('walkway');
      const rests = numericInput('rests');
      if (distance == null || distance < 0) return missing('Geçerli toplam mesafeyi girin.');
      if (walkway != null && (walkway < 5 || walkway > 100)) return missing('Geçerli parkur uzunluğunu girin.');
      if (rests != null && (rests < 0 || !Number.isInteger(rests))) return missing('Dinlenme sayısı tam sayı olmalıdır.');
      value = `${Math.round(distance)} m`;
      note = '6DYT sonucu parkur, yaş, antropometri, tanı ve protokolden etkilenir. Referans, MDC ve MCID yalnız ilgili popülasyon kaynağıyla yorumlanır.';
      meta = [`Parkur: ${walkway ?? 30} m`, `Dinlenme: ${rests ?? 0}`, `Yardımcı cihaz: ${assessmentState.device || 'Yok'}`];
    }
    showResult(value, note, meta, true);
    return true;
  }

  function showResult(value, note, meta, push) {
    $('resultTitle').textContent = currentScale.name;
    $('resultValue').textContent = value;
    $('resultInterpretation').textContent = note;
    $('resultMeta').replaceChildren(...meta.map(text => {
      const item = document.createElement('div');
      item.textContent = text;
      return item;
    }));
    setView('resultView');
    if (push) history.pushState({view:'result', id:currentScale.id, value, note, meta}, '');
  }

  function filterRows(query) {
    const q = query.trim().toLocaleLowerCase('tr-TR');
    if (!q) return [];
    return db.scales.filter(scale => [scale.name,scale.short,scale.purpose,scale.population,...scale.tags,...scale.domains].join(' ').toLocaleLowerCase('tr-TR').includes(q));
  }
  function onSearch() {
    const rows = filterRows(searchInput.value);
    const active = searchInput.value.trim().length > 0;
    categoryList.classList.toggle('hidden', active);
    searchResults.classList.toggle('hidden', !active);
    if (active) {
      renderScaleList(searchResults, rows);
      resultSummary.textContent = `${rows.length} sonuç bulundu`;
    } else {
      renderCatalog();
    }
  }
  function showStored(kind) {
    const ids = kind === 'favorites' ? [...favorites] : readArray(recentKey);
    const rows = ids.map(scaleById).filter(Boolean);
    categoryList.classList.add('hidden');
    searchResults.classList.remove('hidden');
    renderScaleList(searchResults, rows);
    searchInput.value = '';
    resultSummary.textContent = kind === 'favorites' ? `${rows.length} favori ölçek` : `${rows.length} son kullanılan ölçek`;
  }

  $('homeBrand').addEventListener('click', goHome);
  $('resultHome').addEventListener('click', goHome);
  favBtn.addEventListener('click', toggleFavorite);
  $('clearSearch').addEventListener('click', () => { searchInput.value=''; onSearch(); searchInput.focus(); });
  searchInput.addEventListener('input', onSearch);
  $('showFavorites').addEventListener('click', () => showStored('favorites'));
  $('showRecent').addEventListener('click', () => showStored('recent'));
  $('detailTabs').addEventListener('click', event => {
    const button = event.target.closest('button[data-tab]');
    if (!button) return;
    currentTab = button.dataset.tab;
    renderTabs();
    renderDetail();
  });
  $('repeatAssessment').addEventListener('click', () => openAssessment(true));
  $('backToScale').addEventListener('click', () => openScale(currentScale.id, true));
  $('backBtn').addEventListener('click', () => { if (history.length > 1) history.back(); else goHome(); });

  addEventListener('popstate', event => {
    const state = event.state || {view:'catalog'};
    if (state.view === 'category') return openCategory(state.id, false);
    if (state.view === 'detail') return openScale(state.id, false);
    if (state.view === 'assessment') {
      currentScale = scaleById(state.id);
      currentCategory = currentScale?.category || null;
      return openAssessment(false);
    }
    if (state.view === 'result') {
      currentScale = scaleById(state.id);
      currentCategory = currentScale?.category || null;
      if (currentScale && state.value != null) return showResult(state.value, state.note || '', Array.isArray(state.meta)?state.meta:[], false);
      return openScale(state.id, false);
    }
    openCatalog(false);
  });

  validateAssessmentContracts();
  history.replaceState({view:'catalog'}, '');
  renderCatalog();
  updateFavButton();
})();
