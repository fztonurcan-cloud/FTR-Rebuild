(() => {
  'use strict';
  const db = window.FTR_CLINICAL_SCALES;
  if (!db || !Array.isArray(db.scales)) throw new Error('Clinical scales data missing before Turkish evidence');
  const byId = Object.fromEntries(db.scales.map(scale => [scale.id, scale]));

  function add(id, summary, label, url) {
    const scale = byId[id];
    if (!scale) throw new Error(`Turkish evidence target missing: ${id}`);
    scale.turkish = summary;
    scale.turkishEvidence = scale.turkishEvidence || [];
    scale.turkishEvidence.push({label, url});
    if (!scale.sources.some(pair => pair[1] === url)) scale.sources.push([label, url]);
  }

  add('barthel',
    'Türkiye’de Modifiye Barthel İndeksi; inme ve spinal kord yaralanmalı rehabilitasyon hastalarında Türkçeye uyarlanmış, güvenilirlik ve yapı geçerliliği incelenmiştir. Bu kanıt Modifiye Barthel sürümüne aittir; farklı Barthel sürümleri eşdeğer kabul edilmez.',
    'PubMed — Modified Barthel Index Turkey adaptation',
    'https://pubmed.ncbi.nlm.nih.gov/10853723/');

  add('fim',
    'FIM’in Türkiye uyarlaması Ankara Üniversitesi rehabilitasyon ünitesinde inme ve spinal kord yaralanmalı hastalarda incelenmiş; iyi iç tutarlılık, yüksek ICC ve beklenen yapı geçerliliği bildirilmiştir. Ölçeğin lisans koşulları bu psikometrik kanıttan bağımsızdır.',
    'PubMed — Adaptation of FIM for use in Turkey',
    'https://pubmed.ncbi.nlm.nih.gov/11386402/');

  add('katz',
    'Altı maddelik Katz GYA Türkçe sürümü, Türkiye’de yaşayan yaşlı erişkinlerde yüksek iç tutarlılık ve çok yüksek test-tekrar test/gözlemciler arası güvenilirlik ile geçerli ve güvenilir bulunmuştur.',
    'PubMed — Turkish Katz ADL validation',
    'https://pubmed.ncbi.nlm.nih.gov/26328478/');

  add('lawton',
    'Lawton IADL Türkçe uyarlaması yaşlı erişkinlerde yapılmış; 80 katılımcıda geçerlilik incelenmiş ve tüm ölçek için Cronbach alfa 0.843 bildirilmiştir.',
    'PubMed — Turkish Lawton IADL validation',
    'https://pubmed.ncbi.nlm.nih.gov/32743320/');

  add('berg',
    'Türkçe Berg Denge Ölçeği 65 yaş üzeri sağlıklı Türk erişkinlerde doğrulanmıştır; toplam skor için test-tekrar test ICC 0.98, gözlemci içi ICC 0.98 ve gözlemciler arası ICC 0.97 bildirilmiştir. Bu çalışma yaşlı erişkin popülasyonuna özgüdür.',
    'PubMed — Turkish Berg Balance Scale validation',
    'https://pubmed.ncbi.nlm.nih.gov/18489806/');

  add('odi',
    'ODI 2.0 Türkçe sürümü bel ağrılı 95 ayaktan hastada kültürler arası uyarlanmış; test-tekrar test ICC 0.938 ve yüksek iç tutarlılık bildirilmiştir.',
    'PubMed — Turkish Oswestry Disability Index validation',
    'https://pubmed.ncbi.nlm.nih.gov/15129077/');

  add('ndi',
    'Türkçe NDI kronik boyun ağrılı 88 hastada kültürler arası uyarlanmış; test-tekrar test ICC 0.979 ve uygun yapı/geçerlik ilişkileri bildirilmiştir.',
    'PubMed — Turkish Neck Disability Index validation',
    'https://pubmed.ncbi.nlm.nih.gov/18469684/');

  add('dash',
    'DASH Türkçe sürümünün güvenilirlik ve yapı geçerliliği üst ekstremite kas-iskelet yakınması olan 240 endüstri çalışanında incelenmiş; Cronbach alfa 0.91 ve toplam DASH için ICC 0.92 bildirilmiştir. Türkçe geçerlilik, ticari yazılıma gömme lisansı anlamına gelmez.',
    'PubMed — Turkish DASH validity/reliability',
    'https://pubmed.ncbi.nlm.nih.gov/18555973/');

  add('womac',
    'WOMAC LK 3.1 Türkçe sürümü diz osteoartritli fizyoterapi hastalarında geçerli, güvenilir ve değişime duyarlı bulunmuştur; ayrıca Türk kalça/diz OA örnekleminde de psikometrik özellikleri incelenmiştir.',
    'PubMed — Turkish WOMAC validation',
    'https://pubmed.ncbi.nlm.nih.gov/15639634/');
  byId.womac.sources.push(['PubMed — Turkish hip/knee OA WOMAC study','https://pubmed.ncbi.nlm.nih.gov/20169459/']);

  add('hhs',
    'Harris Hip Score Türkçe sürümü farklı kalça patolojileri olan 80 hastada kültürler arası uyarlanmış; test-tekrar test ICC 0.91 ve yeterli geçerlilik/güvenilirlik bildirilmiştir.',
    'PubMed — Turkish Harris Hip Score validation',
    'https://pubmed.ncbi.nlm.nih.gov/25264204/');

  add('gmfcs',
    'GMFCS Expanded & Revised Türkçe sürümünün çocukluk çağı serebral palsisinde gözlemciler arası ve test-tekrar test güvenilirliği incelenmiş; iki hekim arasındaki ICC 0.97 bildirilmiştir. Resmi CanChild kullanım/çeviri koşulları ayrıca korunur.',
    'PubMed — Turkish GMFCS E&R reliability/validity',
    'https://pubmed.ncbi.nlm.nih.gov/22126744/');

  add('gmfm',
    'GMFM-88 ve GMFM-66 Türkçe sürümlerinin psikometrik özellikleri 2024’te 150 serebral palsili çocukta incelenmiş ve klinik kullanım için güvenilirlik/geçerlilik kanıtı bildirilmiştir. Ticari ürün entegrasyonu için CanChild/McMaster hakları ayrıca geçerlidir.',
    'PubMed — Turkish GMFM-88&66 validation 2024',
    'https://pubmed.ncbi.nlm.nih.gov/39334609/');

  add('dgi',
    'Türkçe psikometrik çalışma Modified Dynamic Gait Index (mDGI) sürümüne aittir; yaşlı erişkinlerde Cronbach alfa 0.97, test-tekrar test ve gözlemciler arası ICC 0.95 bildirilmiştir. Orijinal DGI ile mDGI aynı sürüm gibi gösterilmez.',
    'PubMed — Turkish Modified DGI validation',
    'https://pubmed.ncbi.nlm.nih.gov/36121068/');

  add('mmse',
    'Standardize Mini Mental Test Türk toplumunda hafif demans ayrımında incelenmiş; eğitimli örneklemde 23/24 kesimi yüksek duyarlılık/özgüllük göstermiştir. Daha sonraki Türk çalışmaları yaş ve eğitim etkisini vurguladığından tek cut-off evrensel kabul edilmez.',
    'PubMed — Turkish standardized MMSE validation',
    'https://pubmed.ncbi.nlm.nih.gov/12794644/');
  byId.mmse.sources.push(['PubMed — Revised Turkish MMSE educated/uneducated older adults','https://pubmed.ncbi.nlm.nih.gov/19337986/']);
  byId.mmse.sources.push(['PubMed — Turkish MMSE normative psychometric caution','https://pubmed.ncbi.nlm.nih.gov/15729101/']);

  db.turkishEvidenceVersion = '2026-09-03-pubmed-pass-1';
  db.turkishEvidencePolicy = {
    populationNamed: true,
    editionNamed: true,
    psychometricValidationDoesNotGrantCopyright: true,
    noUniversalCutoffInference: true
  };
})();
