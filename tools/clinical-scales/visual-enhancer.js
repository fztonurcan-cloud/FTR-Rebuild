(() => {
  'use strict';
  const db = window.FTR_CLINICAL_SCALES;
  if (!db) throw new Error('Clinical scales data missing before visual enhancer');

  const COLORS = {bone:'#dce9f2', cyan:'#43c7ff', purple:'#b574ff', amber:'#f8be3f', red:'#ff6877', green:'#4de0c1', muted:'#708da5'};
  const line = (x1,y1,x2,y2,c=COLORS.bone,w=3) => `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${c}" stroke-width="${w}" stroke-linecap="round"/>`;
  const circle = (cx,cy,r,c=COLORS.bone,w=3,fill='none') => `<circle cx="${cx}" cy="${cy}" r="${r}" stroke="${c}" stroke-width="${w}" fill="${fill}"/>`;
  const rect = (x,y,w,h,c=COLORS.cyan,rx=5,fill='none') => `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${rx}" stroke="${c}" stroke-width="3" fill="${fill}"/>`;
  const txt = (x,y,t,c=COLORS.bone,s=9,weight=700,anchor='middle') => `<text x="${x}" y="${y}" text-anchor="${anchor}" fill="${c}" font-size="${s}" font-weight="${weight}" font-family="system-ui,Segoe UI,sans-serif">${t}</text>`;
  const path = (d,c=COLORS.bone,w=3,fill='none') => `<path d="${d}" stroke="${c}" stroke-width="${w}" fill="${fill}" stroke-linecap="round" stroke-linejoin="round"/>`;
  const person = (x=70,y=24,s=1,c=COLORS.bone) => [
    circle(x,y,9*s,c,2.5),
    line(x,y+9*s,x,y+48*s,c,3),
    line(x,y+20*s,x-17*s,y+36*s,c,3),
    line(x,y+20*s,x+17*s,y+36*s,c,3),
    line(x,y+48*s,x-14*s,y+76*s,c,3),
    line(x,y+48*s,x+14*s,y+76*s,c,3)
  ].join('');
  const chair = (x=18,y=72,c=COLORS.cyan) => `${rect(x,y,31,7,c,2)}${line(x+3,y+7,x+3,y+34,c,3)}${line(x+28,y+7,x+28,y+34,c,3)}${line(x+3,y,x+3,y-25,c,3)}${line(x+3,y-25,x+28,y-25,c,3)}`;
  const bodyMap = (accent=COLORS.red) => `${person(82,24,.9)}${circle(82,69,7,accent,4,'rgba(255,255,255,.02)')}`;
  const pegGrid = (cols,rows,x0,y0,dx,dy,c=COLORS.cyan) => Array.from({length:cols*rows},(_,i)=>circle(x0+(i%cols)*dx,y0+Math.floor(i/cols)*dy,3.4,c,2)).join('');
  const shell = (title, subtitle, body, accent=COLORS.cyan) => `
    <svg viewBox="0 0 180 150" role="img" aria-label="${title} klinik uygulama görseli">
      <defs>
        <linearGradient id="vg" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#071a2b"/><stop offset="1" stop-color="#030b14"/></linearGradient>
        <filter id="glow"><feGaussianBlur stdDeviation="2.2" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
      </defs>
      <rect x="1" y="1" width="178" height="148" rx="18" fill="url(#vg)" stroke="#173a52"/>
      <rect x="10" y="10" width="160" height="105" rx="14" fill="#04101b" stroke="#153249"/>
      <g filter="url(#glow)">${body}</g>
      ${txt(90,130,title,'#f3f8fc',10,800)}
      ${txt(90,143,subtitle,accent,7.2,700)}
    </svg>`;

  const scenes = {
    barthel: () => shell('Barthel İndeksi','10 GYA • bağımsızlık', `${person(72,24,.72)}${rect(16,22,29,22,COLORS.green,5)}${txt(30,36,'GYA',COLORS.green,8)}${path('M108 36h38M111 36v22m31-22v22',COLORS.cyan,3)}${path('M115 75h28l-5 22h-18z',COLORS.amber,3)}${txt(130,110,'0–100',COLORS.green,10)}`, COLORS.green),
    fim: () => shell('FIM','13 motor + 5 bilişsel', `${person(58,25,.7)}${circle(123,42,22,COLORS.purple,3)}${path('M109 42q7-15 14 0t14 0',COLORS.purple,3)}${txt(123,75,'5 bilişsel',COLORS.purple,7)}${txt(58,112,'13 motor',COLORS.cyan,7)}${txt(90,98,'1–7',COLORS.amber,12)}`, COLORS.purple),
    katz: () => shell('Katz GYA','6 temel aktivite', `${['Banyo','Giyim','WC','Transfer','Kont.','Beslenme'].map((t,i)=>`${rect(15+(i%3)*52,22+Math.floor(i/3)*40,44,29,[COLORS.cyan,COLORS.purple,COLORS.green][i%3],6)}${txt(37+(i%3)*52,40+Math.floor(i/3)*40,t,'#e9f3f9',6.7)}`).join('')}`, COLORS.cyan),
    lawton: () => shell('Lawton–Brody','Enstrümantal GYA', `${rect(16,22,30,45,COLORS.cyan,7)}${circle(31,59,2,COLORS.cyan,2,COLORS.cyan)}${path('M63 29h25l-3 25H67z',COLORS.green,3)}${circle(70,60,3,COLORS.green,2)}${circle(82,60,3,COLORS.green,2)}${rect(103,25,35,28,COLORS.amber,5)}${line(120,53,120,79,COLORS.amber,3)}${circle(120,86,7,COLORS.amber,3)}${txt(90,107,'Telefon • alışveriş • ilaç • finans',COLORS.green,6.5)}`, COLORS.green),
    brunnstrom: () => shell('Brunnstrom','Motor iyileşme evreleri', `${[0,1,2,3,4,5].map(i=>`${circle(24+i*26,37,9,i<2?COLORS.red:(i<4?COLORS.amber:COLORS.green),2)}${txt(24+i*26,41,String(i+1),'#fff',7)}${i<5?line(34+i*26,37,40+i*26,37,COLORS.muted,2):''}`).join('')}${path('M23 83q28-24 52 0t54 0',COLORS.purple,4)}${txt(90,105,'flasidite → sinerji → seçici hareket',COLORS.purple,6.5)}`, COLORS.purple),
    fma: () => shell('Fugl–Meyer','İnme • sensorimotor', `${person(78,21,.8)}${path('M78 42 101 57 125 70',COLORS.red,5)}${path('M78 67 99 101',COLORS.amber,5)}${rect(15,23,32,66,COLORS.cyan,6)}${txt(31,43,'ÜE',COLORS.cyan,9)}${txt(31,57,'66',COLORS.cyan,12)}${txt(31,75,'AE 34',COLORS.amber,7)}${txt(130,102,'Motor 100',COLORS.green,8)}`, COLORS.purple),
    nihss: () => shell('NIHSS','Akut nörolojik defisit', `${circle(62,44,27,COLORS.purple,3)}${path('M46 44q8-17 16 0t16 0',COLORS.purple,3)}${circle(123,29,7,COLORS.cyan,2)}${circle(143,29,7,COLORS.cyan,2)}${line(116,54,149,54,COLORS.red,3)}${path('M122 72q12 10 24 0',COLORS.amber,3)}${txt(132,94,'görme • motor • dil',COLORS.cyan,6.5)}`, COLORS.purple),
    rivermead: () => shell('Rivermead','15 mobilite becerisi', `${rect(12,25,37,20,COLORS.cyan,4)}${line(14,45,14,60,COLORS.cyan,3)}${person(81,24,.62)}${path('M111 101h11V90h11V79h11V68h11',COLORS.amber,3)}${txt(42,102,'yatak',COLORS.cyan,7)}${txt(129,61,'merdiven',COLORS.amber,7)}`, COLORS.cyan),
    mas: () => shell('Modified Ashworth','Pasif harekete direnç', `${circle(53,29,8,COLORS.bone,2)}${line(53,37,53,72,COLORS.bone,3)}${line(53,49,83,51,COLORS.red,5)}${line(83,51,117,35,COLORS.red,5)}${path('M99 28q22 9 13 27',COLORS.cyan,3)}${txt(119,72,'≈1 sn',COLORS.cyan,8)}${txt(90,103,'0 • 1 • 1+ • 2 • 3 • 4',COLORS.amber,8)}`, COLORS.amber),
    tardieu: () => shell('Tardieu / MTS','R1 • R2 • hız', `${circle(65,61,9,COLORS.amber,3)}${line(65,61,30,82,COLORS.bone,4)}${line(65,61,112,47,COLORS.red,4)}${path('M65 61 A45 45 0 0 1 108 91',COLORS.cyan,3)}${txt(117,47,'R1',COLORS.red,8)}${txt(108,94,'R2',COLORS.cyan,8)}${txt(45,25,'V1',COLORS.green,8)}${txt(87,25,'V2',COLORS.amber,8)}${txt(130,25,'V3',COLORS.red,8)}`, COLORS.amber),
    penn: () => shell('Penn Spazm','Sıklık + şiddet', `${person(61,23,.7)}${path('M91 39q19 8 25 24m-22-12q13 6 16 16',COLORS.red,4)}${path('M28 53q-14 13-4 30m6-22q-8 9-2 19',COLORS.red,3)}${txt(126,84,'0–4',COLORS.amber,13)}${txt(126,99,'sıklık',COLORS.amber,7)}${txt(44,105,'1–3 şiddet',COLORS.purple,7)}`, COLORS.red),
    berg: () => shell('Berg Denge','14 görev • 56 puan', `${person(72,21,.78)}${line(72,80,52,109,COLORS.bone,4)}${line(72,80,105,95,COLORS.green,5)}${line(17,111,115,111,COLORS.cyan,3)}${rect(128,61,23,15,COLORS.amber,3)}${txt(139,91,'14',COLORS.amber,13)}${txt(139,103,'görev',COLORS.amber,6.5)}`, COLORS.cyan),
    tug: () => shell('Timed Up & Go','sandalye • 3 m • süre', `${chair(14,69)}${person(79,27,.63,COLORS.green)}${line(57,106,153,106,COLORS.amber,3)}${line(66,100,66,112,COLORS.amber,2)}${line(145,100,145,112,COLORS.amber,2)}${txt(106,99,'3 m',COLORS.amber,8)}${circle(139,36,17,COLORS.cyan,3)}${txt(139,40,'s',COLORS.cyan,12)}`, COLORS.cyan),
    tinetti: () => shell('Tinetti POMA','9 denge + 7 yürüyüş', `${line(90,18,90,108,COLORS.muted,2)}${person(48,25,.63)}${line(22,105,73,105,COLORS.cyan,3)}${person(129,25,.63,COLORS.green)}${path('M108 104h48',COLORS.amber,3)}${txt(48,95,'9 denge',COLORS.cyan,7)}${txt(130,95,'7 gait',COLORS.green,7)}${txt(90,112,'/28',COLORS.amber,9)}`, COLORS.cyan),
    dgi: () => shell('Dynamic Gait Index','8 dinamik yürüyüş görevi', `${person(52,25,.65)}${path('M73 104h75',COLORS.cyan,3)}${rect(94,84,18,20,COLORS.amber,2)}${path('M40 22q10-11 20 0m-22 8q12 9 24 0',COLORS.purple,3)}${txt(126,62,'baş dönüşü',COLORS.purple,7)}${txt(126,77,'engel',COLORS.amber,7)}${txt(126,96,'8 görev /24',COLORS.cyan,7)}`, COLORS.cyan),
    odi: () => shell('Oswestry ODI','Bel ağrısı • özürlülük', `${bodyMap(COLORS.red)}${path('M68 68q14 10 28 0m-29 7q15 9 30 0',COLORS.red,5)}${rect(112,28,38,58,COLORS.cyan,5)}${line(119,42,143,42,COLORS.muted,2)}${line(119,54,143,54,COLORS.muted,2)}${line(119,66,143,66,COLORS.muted,2)}${txt(131,99,'10 bölüm',COLORS.cyan,7)}`, COLORS.red),
    ndi: () => shell('NDI','Boyun • günlük yaşam', `${person(72,23,.72)}${path('M64 34v24m16-24v24',COLORS.red,5)}${circle(72,48,17,COLORS.red,2)}${rect(112,31,34,53,COLORS.cyan,4)}${txt(129,51,'10',COLORS.cyan,11)}${txt(129,64,'bölüm',COLORS.cyan,6.5)}`, COLORS.red),
    dash: () => shell('DASH','Üst ekstremite • 30 madde', `${person(71,23,.72)}${path('M71 44 43 62 22 90',COLORS.red,6)}${path('M71 44 101 61 134 82',COLORS.red,6)}${circle(21,91,7,COLORS.amber,3)}${circle(135,82,7,COLORS.amber,3)}${txt(126,105,'30 madde',COLORS.cyan,7)}`, COLORS.red),
    womac: () => shell('WOMAC','Kalça/diz OA', `${person(70,22,.72)}${circle(57,78,8,COLORS.red,5)}${circle(83,78,8,COLORS.red,5)}${circle(70,55,11,COLORS.amber,4)}${txt(133,40,'Ağrı',COLORS.red,7)}${txt(133,58,'Sertlik',COLORS.amber,7)}${txt(133,76,'Fonksiyon',COLORS.cyan,7)}`, COLORS.red),
    hhs: () => shell('Harris Kalça','Ağrı • fonksiyon • ROM', `${person(68,22,.72)}${circle(55,57,12,COLORS.red,5)}${path('M55 57q17-11 29 1',COLORS.amber,4)}${path('M106 88 A30 30 0 0 1 142 55',COLORS.cyan,3)}${txt(130,99,'/100',COLORS.amber,10)}`, COLORS.red),
    gmfm: () => shell('GMFM','5 kaba motor boyutu', `${circle(23,88,8,COLORS.green,2)}${path('M23 96h24',COLORS.green,3)}${circle(63,66,8,COLORS.cyan,2)}${line(63,74,63,96,COLORS.cyan,3)}${circle(102,43,8,COLORS.amber,2)}${line(102,51,102,90,COLORS.amber,3)}${circle(141,28,8,COLORS.purple,2)}${line(141,36,141,78,COLORS.purple,3)}${txt(90,109,'yatma → oturma → ayakta → yürüme',COLORS.green,6.3)}`, COLORS.green),
    gmfcs: () => shell('GMFCS E&R','CP • Seviye I–V', `${[1,2,3,4,5].map((n,i)=>`${rect(15+i*31,24+i*11,25,68-i*11,[COLORS.green,COLORS.cyan,COLORS.amber,COLORS.purple,COLORS.red][i],5,'rgba(255,255,255,.015)')}${txt(27+i*31,44+i*11,String(n),'#fff',10)}`).join('')}${txt(90,108,'fonksiyonel mobilite düzeyi',COLORS.cyan,7)}`, COLORS.green),
    pdms: () => shell('PDMS','0–5 yaş motor gelişim', `${circle(52,31,11,COLORS.green,2)}${line(52,42,52,75,COLORS.green,3)}${line(52,56,31,69,COLORS.green,3)}${line(52,56,75,68,COLORS.green,3)}${circle(111,68,14,COLORS.amber,3)}${rect(124,25,18,18,COLORS.cyan,3)}${rect(144,43,16,16,COLORS.purple,3)}${txt(118,101,'PDMS-3',COLORS.cyan,9)}`, COLORS.green),
    jebsen: () => shell('Jebsen–Taylor','7 zamanlı el görevi', `${rect(14,20,42,27,COLORS.cyan,4)}${path('M20 33h30',COLORS.cyan,2)}${rect(67,21,24,33,COLORS.purple,3)}${circle(116,30,5,COLORS.amber,2)}${circle(132,30,5,COLORS.amber,2)}${circle(148,30,5,COLORS.amber,2)}${path('M43 78q18-18 36 0v24',COLORS.bone,4)}${rect(99,71,18,27,COLORS.green,3)}${rect(123,65,22,33,COLORS.red,3)}${txt(90,111,'yazı • kart • nesne • beslenme',COLORS.cyan,6.2)}`, COLORS.purple),
    '9hpt': () => shell('Nine-Hole Peg','9 peg • saniye', `${rect(35,18,85,84,COLORS.cyan,8)}${pegGrid(3,3,55,39,23,22,COLORS.cyan)}${path('M132 30v60',COLORS.amber,4)}${circle(132,27,4,COLORS.amber,2,COLORS.amber)}${circle(132,45,4,COLORS.amber,2,COLORS.amber)}${circle(132,63,4,COLORS.amber,2,COLORS.amber)}${txt(151,98,'sec',COLORS.amber,8)}`, COLORS.purple),
    purdue: () => shell('Purdue Pegboard','iki el + montaj', `${rect(22,17,91,89,COLORS.cyan,7)}${pegGrid(4,4,40,34,18,18,COLORS.cyan)}${circle(137,31,7,COLORS.amber,3)}${rect(130,51,14,14,COLORS.purple,3)}${path('M129 85h18m-9-9v18',COLORS.green,4)}${txt(138,107,'montaj',COLORS.green,6.5)}`, COLORS.purple),
    sf36: () => shell('SF-36','8 sağlık boyutu', `${circle(88,62,38,COLORS.cyan,2)}${[0,45,90,135].map(a=>{const r=a*Math.PI/180;return line(88,62,88+38*Math.cos(r),62+38*Math.sin(r),COLORS.muted,1.5)}).join('')}${path('M88 30 110 45 119 68 102 91 76 94 57 74 63 46Z',COLORS.purple,4,'rgba(181,116,255,.08)')}${txt(143,40,'8',COLORS.amber,13)}${txt(143,53,'boyut',COLORS.amber,6.5)}`, COLORS.purple),
    mmse: () => shell('MMSE','Bilişsel tarama', `${circle(67,48,28,COLORS.purple,3)}${path('M50 48q8-17 16 0t16 0',COLORS.purple,3)}${circle(129,43,20,COLORS.cyan,3)}${line(129,43,129,29,COLORS.cyan,2)}${line(129,43,142,50,COLORS.cyan,2)}${path('M111 82h36v20h-36z',COLORS.amber,3)}${txt(129,96,'30',COLORS.amber,10)}`, COLORS.purple),
    '6mwt': () => shell('6 Dakika Yürüme','mesafe • standart parkur', `${person(50,30,.6,COLORS.green)}${line(20,104,158,104,COLORS.cyan,3)}${path('M28 104l7-18 7 18m96 0 7-18 7 18',COLORS.amber,3)}${circle(122,39,22,COLORS.cyan,3)}${txt(122,43,'6:00',COLORS.cyan,9)}${txt(93,95,'metre',COLORS.green,8)}`, COLORS.green)
  };

  const aliases = { '9hpt':'9hpt', '6mwt':'6mwt' };
  const render = () => {
    const visual = document.getElementById('scaleVisual');
    const title = document.getElementById('scaleTitle');
    if (!visual || !title || !title.textContent.trim()) return;
    const scale = db.scales.find(item => item.name === title.textContent.trim());
    if (!scale) return;
    const key = aliases[scale.id] || scale.id;
    const builder = scenes[key];
    if (!builder) return;
    const token = `ftr-clinical-${scale.id}`;
    if (visual.dataset.enhancedFor === token) return;
    visual.innerHTML = builder();
    visual.dataset.enhancedFor = token;
  };

  const target = document.getElementById('detailView');
  if (target) new MutationObserver(render).observe(target, {subtree:true, childList:true, characterData:true, attributes:true});
  document.addEventListener('click', () => setTimeout(render, 0), true);
  render();
})();
