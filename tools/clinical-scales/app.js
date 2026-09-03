(() => {
  'use strict';
  const db = window.FTR_CLINICAL_SCALES;
  if (!db) throw new Error('Clinical scales data missing');

  const $ = id => document.getElementById(id);
  const app = $('clinicalApp');
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

  function readArray(key) {
    try { const v = JSON.parse(localStorage.getItem(key) || '[]'); return Array.isArray(v) ? v : []; }
    catch { return []; }
  }
  function writeArray(key, values) { try { localStorage.setItem(key, JSON.stringify(values)); } catch {} }
  function setView(id) { views.forEach(v => v.classList.toggle('active', v.id === id)); scrollTo({top:0, behavior:'instant'}); }
  function categoryById(id) { return db.categories.find(x => x.id === id); }
  function scaleById(id) { return db.scales.find(x => x.id === id); }
  function scalesForCategory(id) { return db.scales.filter(x => x.category === id); }
  function goHome() { location.href = '../index.html'; }

  function iconSvg(name) {
    const common = 'viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"';
    const paths = {
      activity:'<circle cx="24" cy="8" r="4"/><path d="M18 17h12l3 11-6 3-3-8-4 8-7-3 5-11Zm6 14v10m-7 0 7-10 7 10"/>',
      brain:'<path d="M20 8c-6-3-11 2-9 8-5 2-5 9 0 11-2 7 5 11 10 7m7-26c6-3 11 2 9 8 5 2 5 9 0 11 2 7-5 11-10 7M24 7v31M15 16c4 0 5 2 5 5m-6 7c5 0 6-2 6-5m13-7c-4 0-5 2-5 5m6 7c-5 0-6-2-6-5"/>',
      wave:'<path d="M5 26h7l4-13 7 25 6-19 4 7h10"/>',
      balance:'<circle cx="24" cy="8" r="4"/><path d="M24 12v13m0-8-11 8m11-8 11 8M24 25l-8 15m8-15 8 15M8 40h32"/>',
      joint:'<path d="M17 6c6 5 7 10 6 17m8-17c-6 5-7 10-6 17M19 42c5-6 6-12 4-19m6 19c-5-6-6-12-4-19M20 21h8m-8 6h8"/>',
      child:'<circle cx="24" cy="9" r="5"/><path d="M24 14v13m0-7-10 5m10-5 10 5M24 27l-9 13m9-13 9 13"/>',
      hand:'<path d="M13 25V13c0-4 5-4 5 0v8-12c0-4 5-4 5 0v12V8c0-4 5-4 5 0v13-10c0-4 5-4 5 0v15l3-5c2-3 7 0 5 4l-6 13c-2 4-6 6-11 6-8 0-13-7-14-14l-1-5c-1-4 4-5 6 0l2 5"/>',
      heart:'<path d="M24 41S6 30 6 17c0-9 11-12 18-4 7-8 18-5 18 4 0 13-18 24-18 24Z"/><path d="M12 25h7l3-7 5 14 3-7h6"/>'
    };
    return `<svg ${common}>${paths[name] || paths.activity}</svg>`;
  }

  function scene(key) {
    const h = '<circle class="skeleton" cx="60" cy="24" r="11"/><path class="skeleton" d="M60 35v45M60 46 43 61m17-15 17 15M60 80 46 111m14-31 14 31"/>';
    const svg = body => `<svg viewBox="0 0 120 130" role="img">${body}</svg>`;
    const scenes = {
      adl: h + '<path class="soft" d="M86 30h22v32H86zM91 39h12m-12 8h12"/><path class="warm" d="M43 61 28 79m49-18 13 17"/>',
      care: h + '<path class="soft" d="M15 17h23v25H15zM19 24h15m-15 7h15M83 18h23v25H83z"/><path class="accent" d="M47 96h26"/>',
      iadl: h + '<rect class="soft" x="86" y="20" width="20" height="35" rx="4"/><path class="warm" d="M18 88h28v22H18zM22 88v-9h20v9"/>',
      stroke: h + '<path class="danger" d="M60 35v45m0-33 17 15m-17 18 14 31"/><path class="soft" d="M25 18c10-9 25-8 32 1"/>',
      'stroke-arm': h + '<path class="danger" d="M60 46 77 61 94 74"/><circle class="fill-soft" cx="93" cy="74" r="10"/><path class="soft" d="M82 94h25"/>',
      'neuro-exam': h + '<path class="soft" d="M35 16h-19v30h23M17 23h15m-15 8h13m-13 8h10"/><path class="accent" d="M48 20c8-5 16-5 24 0m-24 7c8 5 16 5 24 0"/>',
      mobility: h + '<path class="soft" d="M12 110h96M86 101h18v9H86z"/><path class="warm" d="M42 60 27 83m50-22 13 20"/>',
      'passive-rom': '<circle class="skeleton" cx="37" cy="26" r="10"/><path class="skeleton" d="M37 36v40m0-25 28 3 20-15M37 76l-10 35m10-35 12 35"/><path class="danger" d="M65 54 85 39"/><path class="soft" d="M78 32q17 8 9 22"/>',
      goniometer: '<circle class="skeleton" cx="48" cy="38" r="10"/><path class="skeleton" d="M48 48v35m0-21 26 5 22-16M48 83l-10 27m10-27 13 27"/><circle class="warm" cx="74" cy="67" r="8"/><path class="warm" d="M74 67 98 55m-24 12 22 14"/>',
      spasm: h + '<path class="danger" d="M80 42c13 5 20 14 21 26M83 50c8 4 13 9 14 17M39 48c-10 5-16 13-17 23"/><path class="warm" d="M87 75l8 6-7 5"/>',
      'single-leg':'<circle class="skeleton" cx="54" cy="22" r="10"/><path class="skeleton" d="M54 32v43m0-29-21 18m21-18 21 17M54 75 43 112m11-37 27 19"/><path class="soft" d="M17 113h55"/><path class="accent" d="M76 91q10 4 15 13"/>',
      'chair-walk':'<path class="skeleton" d="M12 78h28v27H12m4-27V61m21 17V61"/><circle class="soft" cx="57" cy="33" r="9"/><path class="soft" d="M57 42v31m0-21 14 11m-14 10-11 31m11-31 17 26"/><path class="warm" d="M82 105h26M92 94l16 11-16 11"/>',
      gait:'<circle class="skeleton" cx="42" cy="25" r="9"/><path class="skeleton" d="M42 34v38m0-26-16 15m16-15 18 14M42 72 27 108m15-36 20 29"/><path class="soft" d="M67 104h38m-27-8 10 8-10 8"/>',
      'obstacle-gait':'<circle class="skeleton" cx="40" cy="25" r="9"/><path class="skeleton" d="M40 34v38m0-26-15 13m15-13 17 14M40 72 26 107m14-35 24 20"/><path class="warm" d="M68 104h12V88h15v16h13"/><path class="soft" d="M74 70q12-9 24 0"/>',
      'low-back': h + '<path class="danger" d="M49 69q11 8 22 0M48 75q12 7 24 0"/><path class="soft" d="M38 64q22-10 44 0"/>',
      neck: h + '<path class="danger" d="M52 34v18m16-18v18"/><path class="soft" d="M46 52q14 8 28 0"/>',
      'upper-limb': h + '<path class="danger" d="M60 46 42 62 27 83m33-37 20 15 17 20"/><circle class="fill-soft" cx="25" cy="84" r="9"/>',
      'knee-hip': h + '<circle class="danger" cx="48" cy="80" r="7"/><circle class="danger" cx="72" cy="80" r="7"/><circle class="warm" cx="60" cy="51" r="10"/>',
      hip: h + '<path class="warm" d="M42 68q18 11 36 0M47 60q13 8 26 0"/><circle class="danger" cx="48" cy="70" r="6"/>',
      'child-motor':'<circle class="skeleton" cx="57" cy="28" r="12"/><path class="skeleton" d="M57 40v32m0-17-25 12m25-12 23 11M57 72 35 96m22-24 24 22"/><path class="soft" d="M15 108h90"/><circle class="warm" cx="95" cy="79" r="9"/>',
      'child-levels':'<path class="soft" d="M10 108h100M18 92h18v16m6-34h18v34m6-52h18v52m6-72h18v72"/>' + '<circle class="skeleton" cx="28" cy="42" r="7"/><path class="skeleton" d="M28 49v27m0-17-10 9m10-9 10 9m-10 8-7 15m7-15 8 15"/>',
      'child-play':'<circle class="skeleton" cx="48" cy="28" r="11"/><path class="skeleton" d="M48 39v32m0-18-22 13m22-13 22 14M48 71 33 99m15-28 18 27"/><circle class="warm" cx="88" cy="82" r="14"/><path class="soft" d="M77 82h22M88 71v22"/>',
      'hand-tasks':'<path class="skeleton" d="M35 91V50c0-8 10-8 10 0v18-30c0-8 10-8 10 0v30-34c0-8 10-8 10 0v34-25c0-8 10-8 10 0v38l8-12c5-7 15 0 10 8L78 105c-6 10-19 15-31 10-8-4-12-13-12-24Z"/><path class="soft" d="M15 26h20v13H15zm72 6h18v18H87z"/>',
      pegboard9:'<rect class="skeleton" x="29" y="25" width="62" height="82" rx="10"/><g class="soft">' + [[45,42],[60,42],[75,42],[45,62],[60,62],[75,62],[45,82],[60,82],[75,82]].map(p=>`<circle cx="${p[0]}" cy="${p[1]}" r="4"/>`).join('') + '</g><path class="warm" d="M18 46v39m-5-32h10"/>',
      pegboard:'<rect class="skeleton" x="25" y="18" width="70" height="94" rx="8"/><g class="soft"><path d="M40 34v14m20-14v14m20-14v14M40 62v14m20-14v14m20-14v14M40 90v14m20-14v14m20-14v14"/></g><circle class="warm" cx="104" cy="41" r="6"/><rect class="warm" x="99" y="58" width="10" height="10"/>',
      'quality-life':'<path class="soft" d="M18 98V72h14v26m7 0V51h14v47m7 0V63h14v35m7 0V34h14v64"/><path class="warm" d="M15 105h93"/><path class="accent" d="M22 40q12-18 24 0t24 0t24 0"/>',
      cognition:'<path class="skeleton" d="M33 72c-20-5-20-35-3-39-4-16 20-23 29-10 10-14 34-6 29 11 17 6 15 34-2 39-2 20-35 20-39 3-6 13-27 6-14-4Z"/><path class="soft" d="M55 25v58m-20-32h39m-30-16 20 34m0-34-20 34"/>',
      walkway:'<path class="soft" d="M12 101h96M27 91v20m66-20v20"/><circle class="skeleton" cx="53" cy="29" r="9"/><path class="skeleton" d="M53 38v36m0-24-15 13m15-13 16 12M53 74 38 103m15-29 18 27"/><path class="warm" d="M19 84h82M22 79l-7 5 7 5m76-10 7 5-7 5"/>'
    };
    return svg(scenes[key] || scenes.adl);
  }

  function registerRecent(id) {
    const next = readArray(recentKey).filter(x => x !== id); next.unshift(id); writeArray(recentKey, next.slice(0,8));
  }
  function updateFavButton() { favBtn.textContent = currentScale && favorites.has(currentScale.id) ? '★' : '☆'; favBtn.disabled = !currentScale; }
  function toggleFavorite() {
    if (!currentScale) return;
    if (favorites.has(currentScale.id)) favorites.delete(currentScale.id); else favorites.add(currentScale.id);
    writeArray(favoriteKey,[...favorites]); updateFavButton();
  }

  function categoryButton(cat) {
    const count = scalesForCategory(cat.id).length;
    const button = document.createElement('button'); button.type='button'; button.className='category-card'; button.style.setProperty('--card-accent',cat.accent);
    button.innerHTML = `<span class="card-icon">${iconSvg(cat.icon)}</span><span class="card-copy"><strong>${cat.title}</strong><small>${scalesForCategory(cat.id).map(s=>s.short).join(' • ')}</small></span><span class="card-count"><small>${count}</small><b>›</b></span>`;
    button.addEventListener('click',()=>openCategory(cat.id,true)); return button;
  }
  function scaleButton(scale) {
    const cat=categoryById(scale.category); const button=document.createElement('button'); button.type='button'; button.className='scale-card'; button.style.setProperty('--card-accent',cat.accent);
    button.innerHTML=`<span class="card-icon">${iconSvg(cat.icon)}</span><span class="card-copy"><strong>${scale.name}</strong><small>${scale.short} • ${scale.purpose}</small></span><span class="card-count"><span class="license-dot ${scale.rights.mode==='open'?'':'restricted'}"></span><b>›</b></span>`;
    button.addEventListener('click',()=>openScale(scale.id,true)); return button;
  }
  function renderCatalog() { categoryList.replaceChildren(...db.categories.map(categoryButton)); resultSummary.textContent=`${db.categories.length} kategori • ${db.scales.length} klinik değerlendirme aracı`; }
  function renderScaleList(target, rows) { target.replaceChildren(...rows.map(scaleButton)); if(!rows.length){const e=document.createElement('div');e.className='empty-state';e.textContent='Bu filtrede ölçek bulunamadı.';target.append(e);} }

  function openCatalog(push=false) { currentCategory=null; currentScale=null; updateFavButton(); searchInput.value=''; searchResults.classList.add('hidden'); categoryList.classList.remove('hidden'); renderCatalog(); setView('catalogView'); if(push) history.pushState({view:'catalog'},''); }
  function openCategory(id,push=false) { const cat=categoryById(id); if(!cat)return; currentCategory=id; currentScale=null; $('categoryTitle').textContent=cat.title; const rows=scalesForCategory(id); $('categorySubtitle').textContent=`${rows.length} klinik değerlendirme aracı`; renderScaleList(categoryScales,rows); updateFavButton(); setView('categoryView'); if(push)history.pushState({view:'category',id},''); }
  function openScale(id,push=false) { const scale=scaleById(id); if(!scale)return; currentScale=scale; currentCategory=scale.category; currentTab='about'; registerRecent(id); $('scaleVisual').innerHTML=scene(scale.visual); $('scaleShort').textContent=scale.short; $('scaleTitle').textContent=scale.name; $('rightsChip').textContent=scale.rights.label; $('durationChip').textContent=scale.duration; updateFavButton(); renderTabs(); renderDetail(); setView('detailView'); if(push)history.pushState({view:'detail',id},''); }

  function renderTabs(){ document.querySelectorAll('#detailTabs button').forEach(b=>b.classList.toggle('active',b.dataset.tab===currentTab)); }
  function bullet(items){return `<ul>${items.map(x=>`<li>${x}</li>`).join('')}</ul>`;}
  function renderDetail(){
    const s=currentScale;if(!s)return; let html='';
    if(currentTab==='about') html=`<h2>Ne ölçer?</h2><p>${s.purpose}</p><div class="info-grid"><div class="info-cell"><b>Hedef grup</b><span>${s.population}</span></div><div class="info-cell"><b>Süre</b><span>${s.duration}</span></div><div class="info-cell"><b>Ekipman</b><span>${s.equipment}</span></div><div class="info-cell"><b>Türkçe kanıt</b><span>${s.turkish}</span></div></div><h2 style="margin-top:17px">Değerlendirme alanları</h2>${bullet(s.domains)}`;
    if(currentTab==='apply') html=`<h2>Uygulama çerçevesi</h2><p>${s.format}</p><p><b>Hedef popülasyon:</b> ${s.population}</p><p><b>Gerekli ekipman:</b> ${s.equipment}</p><p><b>Tahmini süre:</b> ${s.duration}</p><div class="rights-box ${s.rights.mode==='open'?'open':''}"><b>${s.rights.label}</b><br>${s.rights.note}</div>`;
    if(currentTab==='score') html=`<h2>Puanlama</h2><p>${s.format}</p>${s.interactive?'<p>Bu araç için FTR Akademi içinde kaynak sözleşmesine uygun interaktif kayıt/puanlama açılabilir.</p>':'<p>Bu ölçekte lisans veya resmi form koşulları nedeniyle FTR Akademi tam madde metnini yeniden üretmez. Puanlama prensibi eğitimsel olarak açıklanır.</p>'}`;
    if(currentTab==='interpret') html=`<h2>Klinik yorumlama</h2><p>${s.interpretation}</p><p><b>Türkçe kullanım:</b> ${s.turkish}</p><div class="rights-box ${s.rights.mode==='open'?'open':''}">Sonuç tek başına tanı veya tedavi kararı değildir. Ölçeğin validasyon popülasyonu ve standardize protokolü dikkate alınmalıdır.</div>`;
    if(currentTab==='sources') html=`<h2>Kaynaklar ve hak durumu</h2><div class="source-list">${s.sources.map(([label,url])=>`<a href="${url}" target="_blank" rel="noopener">${label}<br><small>${url}</small></a>`).join('')}</div><div class="rights-box ${s.rights.mode==='open'?'open':''}"><b>${s.rights.label}</b><br>${s.rights.note}</div>`;
    detailBody.innerHTML=html; renderActionArea();
  }
  function renderActionArea(){ const s=currentScale;if(!s)return; if(s.interactive){actionArea.innerHTML='<button id="startAssessment" class="primary" type="button">Değerlendirmeyi Başlat</button>'; $('startAssessment').addEventListener('click',()=>openAssessment(true));} else {actionArea.innerHTML=`<div class="disabled-note"><b>Güvenli uygulama modu:</b> Bu ölçeğin telif/lisans veya resmi form koşulu netleşmeden tam anket maddeleri FTR Akademi içine kopyalanmayacaktır. Eğitimsel bilgiler ve resmi kaynaklar kullanılabilir.</div>`;}}

  const BERG=['Oturmadan ayağa kalkma','Desteksiz ayakta durma','Desteksiz oturma','Ayakta durmadan oturma','Transfer','Gözler kapalı ayakta durma','Ayaklar bitişik ayakta durma','Öne uzanma','Yerden nesne alma','Arkaya bakmak için dönme','360° dönme','Basamağa dönüşümlü ayak koyma','Tandem duruş','Tek ayak üzerinde durma'];
  const TINETTI=[['Oturma dengesi',1],['Ayağa kalkma',2],['Ayağa kalkma denemeleri',2],['İlk ayakta duruş dengesi',2],['Ayakta duruş dengesi',2],['Hafif itmeye yanıt',2],['Gözler kapalı denge',1],['360° dönme',2],['Oturma',2],['Yürüyüş başlatma',1],['Adım uzunluğu ve yüksekliği',2],['Adım simetrisi',1],['Adım devamlılığı',1],['Yürüme yolu',2],['Gövde',2],['Yürüme tabanı',1]];
  const DGI=['Düz zeminde yürüme','Yürüme hızını değiştirme','Yatay baş hareketleriyle yürüme','Dikey baş hareketleriyle yürüme','Yürürken pivot dönüş','Engelin üzerinden geçme','Engelin etrafından geçme','Merdiven'];

  function openAssessment(push=false){ const s=currentScale;if(!s?.interactive)return; assessmentState={}; $('assessmentShort').textContent=s.short; $('assessmentTitle').textContent=s.name; $('assessmentProgress').textContent='Kaynak sözleşmesine uygun klinik kayıt'; renderAssessment(); setView('assessmentView'); if(push)history.pushState({view:'assessment',id:s.id},''); }
  function setAssessmentValue(key,value,button,scope){assessmentState[key]=value;if(button){scope.querySelectorAll(`[data-key="${CSS.escape(key)}"]`).forEach(x=>x.classList.remove('selected'));button.classList.add('selected');}}
  function optionButtons(key,options,scopeMax=null){return `<div class="option-grid">${options.map(v=>`<button class="score-option" type="button" data-key="${key}" data-value="${v}">${v}</button>`).join('')}</div>`;}
  function scoredItems(items,maxFn){ return items.map((label,i)=>{const max=typeof maxFn==='function'?maxFn(i):maxFn;return `<section class="assessment-card"><h2>${i+1}. ${label}</h2><p>Bu ekranda yalnız skor seçilir; standardize uygulama kriterleri “Uygulama” bölümünden kontrol edilmelidir.</p>${optionButtons(`i${i}`,Array.from({length:max+1},(_,x)=>x))}</section>`;}).join(''); }
  function renderAssessment(){ const s=currentScale; let html='',actions='<button id="cancelAssessment" type="button">İptal</button><button id="finishAssessment" class="primary" type="button">Sonucu Hesapla</button>';
    switch(s.interactive.kind){
      case 'mas': html=`<section class="assessment-card"><h2>Kas tonusu derecesi</h2><p>Değerlendirilen kas/eklem ve tarafı klinik notunuza ayrıca kaydedin.</p>${optionButtons('grade',s.interactive.options)}</section>`; break;
      case 'tardieu': html=`<section class="assessment-card"><h2>R1 / R2 açıları</h2><p>R2: V1’de tam pasif hareket; R1: hızlı V3’te yakalama/klonus açısı.</p><div class="field-grid"><div class="field"><label>R1 (°)</label><input data-field="r1" type="number" min="-180" max="180" step="1"></div><div class="field"><label>R2 (°)</label><input data-field="r2" type="number" min="-180" max="180" step="1"></div></div></section><section class="assessment-card"><h2>Kas reaksiyon kalitesi</h2><p>Kullanılan Tardieu sürümünün 0–5/0–4 tanımıyla tutarlı olun.</p>${optionButtons('quality',['0','1','2','3','4','5'])}</section>`; break;
      case 'penn': html=`<section class="assessment-card"><h2>Spazm sıklığı</h2><p>0: spazm yok; 1–4 artan sıklık dereceleri.</p>${optionButtons('frequency',['0','1','2','3','4'])}</section><section class="assessment-card"><h2>Spazm şiddeti</h2><p>Sıklık 0 ise şiddet bölümü uygulanmaz.</p>${optionButtons('severity',['1','2','3'])}</section>`; break;
      case 'berg': html=scoredItems(BERG,4); break;
      case 'time': html=`<section class="assessment-card"><h2>TUG süresi</h2><p>Sandalyeden kalk → 3 m yürü → dön → geri yürü → otur.</p><div class="field"><label>Süre (saniye)</label><input data-field="time" type="number" min="0" max="600" step="0.01" inputmode="decimal"></div></section><section class="assessment-card"><h2>Yardımcı cihaz</h2><div class="field"><select data-field="device"><option value="Yok">Yok</option><option value="Baston">Baston</option><option value="Walker">Walker</option><option value="Diğer">Diğer</option></select></div></section>`; break;
      case 'tinetti': html=scoredItems(TINETTI.map(x=>x[0]),i=>TINETTI[i][1]); break;
      case 'dgi': html=scoredItems(DGI,3); break;
      case 'hand-time': html=`<section class="assessment-card"><h2>9-HPT zaman kaydı</h2><div class="field-grid"><div class="field"><label>El</label><select data-field="hand"><option>Sağ</option><option>Sol</option></select></div><div class="field"><label>Süre (sn)</label><input data-field="time" type="number" min="0" max="600" step="0.01"></div></div></section>`; break;
      case '6mwt': html=`<section class="assessment-card"><h2>6 dakika yürüme kaydı</h2><div class="field-grid"><div class="field"><label>Toplam mesafe (m)</label><input data-field="distance" type="number" min="0" max="3000" step="1"></div><div class="field"><label>Parkur uzunluğu (m)</label><input data-field="walkway" type="number" min="5" max="100" step="1" value="30"></div><div class="field"><label>Dinlenme sayısı</label><input data-field="rests" type="number" min="0" max="50" step="1" value="0"></div><div class="field"><label>Yardımcı cihaz</label><select data-field="device"><option>Yok</option><option>Baston</option><option>Walker</option><option>Diğer</option></select></div></div></section><section class="assessment-card"><h2>Standardizasyon hatırlatması</h2><p>Dinlenme sırasında kronometre devam eder. Seri takipte aynı parkur ve yardımcı cihazı mümkün olduğunca koruyun.</p></section>`; break;
    }
    assessmentBody.innerHTML=html; assessmentActions.innerHTML=actions; assessmentBody.querySelectorAll('.score-option').forEach(b=>b.addEventListener('click',()=>setAssessmentValue(b.dataset.key,b.dataset.value,b,b.closest('.assessment-card')))); assessmentBody.querySelectorAll('[data-field]').forEach(el=>el.addEventListener('input',()=>assessmentState[el.dataset.field]=el.value)); $('cancelAssessment').addEventListener('click',()=>history.back()); $('finishAssessment').addEventListener('click',finishAssessment);
  }

  function numericInput(name){ const raw=assessmentState[name]; const n=Number(raw); return raw==null||raw===''||!Number.isFinite(n)?null:n; }
  function finishAssessment(){ const s=currentScale; let value='',note='',meta=[]; const missing=msg=>{alert(msg);return false;};
    if(s.interactive.kind==='mas'){if(assessmentState.grade==null)return missing('MAS derecesini seçin.');value=`MAS ${assessmentState.grade}`;note='Derece pasif harekete karşı artmış tonusu tanımlar; spastisitenin hız bağımlı tüm özelliklerini tek başına temsil etmez.';}
    if(s.interactive.kind==='tardieu'){const r1=numericInput('r1'),r2=numericInput('r2');if(r1==null||r2==null||assessmentState.quality==null)return missing('R1, R2 ve reaksiyon kalitesini girin.');value=`R2−R1: ${(r2-r1).toFixed(0)}°`;note='R2−R1 farkı dinamik ton bileşenini yorumlamaya yardımcı olur; eklem, kas, pozisyon ve hız kaydedilmelidir.';meta=[`R1: ${r1}°`,`R2: ${r2}°`,`Reaksiyon: ${assessmentState.quality}`];}
    if(s.interactive.kind==='penn'){if(assessmentState.frequency==null)return missing('Spazm sıklığını seçin.');if(assessmentState.frequency!=='0'&&assessmentState.severity==null)return missing('Spazm şiddetini seçin.');value=`Sıklık ${assessmentState.frequency}/4`;note=assessmentState.frequency==='0'?'Spazm bildirilmedi; şiddet bölümü uygulanmaz.':'Sıklık ve şiddet birlikte kaydedilmelidir; skor hasta bildirimidir.';if(assessmentState.severity)meta=[`Şiddet: ${assessmentState.severity}/3`];}
    if(s.interactive.kind==='berg'||s.interactive.kind==='dgi'||s.interactive.kind==='tinetti'){const count=s.interactive.kind==='berg'?BERG.length:s.interactive.kind==='dgi'?DGI.length:TINETTI.length;let total=0;for(let i=0;i<count;i++){if(assessmentState[`i${i}`]==null)return missing(`Tüm ${count} maddeleri puanlayın.`);total+=Number(assessmentState[`i${i}`]);}value=`${total} / ${s.interactive.max}`;note=s.interactive.kind==='berg'?'Yüksek skor daha iyi dengeyi gösterir. Düşme riski cut-off’ları tanı ve popülasyona göre değişir; tek evrensel eşik kullanılmaz.':s.interactive.kind==='dgi'?'Yüksek skor daha iyi dinamik yürüme dengesini gösterir; tanıya özgü cut-off/MCID ile yorumlanmalıdır.':'Yüksek skor daha iyi denge-yürüyüş performansını gösterir; kullanılan POMA sürümü ve popülasyon birlikte belirtilmelidir.';}
    if(s.interactive.kind==='time'){const t=numericInput('time');if(t==null)return missing('Süreyi girin.');value=`${t.toFixed(2)} sn`;note='Daha kısa süre genellikle daha iyi fonksiyonel mobiliteyi gösterir. Tek bir evrensel düşme-risk eşiği yoktur.';meta=[`Yardımcı cihaz: ${assessmentState.device||'Yok'}`];}
    if(s.interactive.kind==='hand-time'){const t=numericInput('time');if(t==null)return missing('Süreyi girin.');value=`${t.toFixed(2)} sn`;note='Daha kısa süre daha iyi parmak becerisini gösterir. Yaş, test edilen el, dominantlık ve pano standardı norm yorumunda önemlidir.';meta=[`El: ${assessmentState.hand||'Sağ'}`];}
    if(s.interactive.kind==='6mwt'){const d=numericInput('distance');if(d==null)return missing('Toplam mesafeyi girin.');value=`${Math.round(d)} m`;note='6DYT sonucu parkur, yaş, antropometri, tanı ve protokolden etkilenir. MDC/MCID yalnız ilgili popülasyon kaynağıyla yorumlanır.';meta=[`Parkur: ${assessmentState.walkway||30} m`,`Dinlenme: ${assessmentState.rests||0}`,`Yardımcı cihaz: ${assessmentState.device||'Yok'}`];}
    showResult(value,note,meta,true); return true;
  }
  function showResult(value,note,meta,push){$('resultTitle').textContent=currentScale.name;$('resultValue').textContent=value;$('resultInterpretation').textContent=note;$('resultMeta').replaceChildren(...meta.map(x=>{const d=document.createElement('div');d.textContent=x;return d;}));setView('resultView');if(push)history.pushState({view:'result',id:currentScale.id},'');}

  function filterRows(query){const q=query.trim().toLocaleLowerCase('tr-TR');if(!q)return[];return db.scales.filter(s=>[s.name,s.short,s.purpose,s.population,...s.tags,...s.domains].join(' ').toLocaleLowerCase('tr-TR').includes(q));}
  function onSearch(){const rows=filterRows(searchInput.value);const active=searchInput.value.trim().length>0;categoryList.classList.toggle('hidden',active);searchResults.classList.toggle('hidden',!active);if(active){renderScaleList(searchResults,rows);resultSummary.textContent=`${rows.length} sonuç bulundu`;}else renderCatalog();}
  function showStored(kind){const ids=kind==='favorites'?[...favorites]:readArray(recentKey);const rows=ids.map(scaleById).filter(Boolean);categoryList.classList.add('hidden');searchResults.classList.remove('hidden');renderScaleList(searchResults,rows);searchInput.value='';resultSummary.textContent=kind==='favorites'?`${rows.length} favori ölçek`:`${rows.length} son kullanılan ölçek`;}

  $('homeBrand').addEventListener('click',goHome); $('resultHome').addEventListener('click',goHome); favBtn.addEventListener('click',toggleFavorite); $('clearSearch').addEventListener('click',()=>{searchInput.value='';onSearch();searchInput.focus();}); searchInput.addEventListener('input',onSearch); $('showFavorites').addEventListener('click',()=>showStored('favorites')); $('showRecent').addEventListener('click',()=>showStored('recent'));
  $('detailTabs').addEventListener('click',e=>{const b=e.target.closest('button[data-tab]');if(!b)return;currentTab=b.dataset.tab;renderTabs();renderDetail();});
  $('repeatAssessment').addEventListener('click',()=>openAssessment(true)); $('backToScale').addEventListener('click',()=>openScale(currentScale.id,true));
  $('backBtn').addEventListener('click',()=>{if(history.length>1)history.back();else goHome();});
  addEventListener('popstate',e=>{const st=e.state||{view:'catalog'};if(st.view==='category')openCategory(st.id,false);else if(st.view==='detail'){openScale(st.id,false);}else if(st.view==='assessment'){currentScale=scaleById(st.id);openAssessment(false);}else if(st.view==='result'){currentScale=scaleById(st.id);openScale(st.id,false);}else openCatalog(false);});

  history.replaceState({view:'catalog'},''); renderCatalog(); updateFavButton();
})();
