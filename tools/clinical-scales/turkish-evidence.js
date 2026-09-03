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

  add('brunnstrom',
    'Brunnstrom evreleri Türkiye’de inme rehabilitasyonu çalışmalarında klinik karşılaştırma ölçütü olarak kullanılmaktadır. Örneğin Türkçe Trunk Impairment Scale validasyonunda Brunnstrom evreleri yapı geçerliliği analizine dahil edilmiştir. Bu, Brunnstrom için ayrı bir Türkçe çeviri/validasyon çalışması olduğu anlamına gelmez.',
    'PubMed — Turkey stroke study using Brunnstrom stages as convergent evidence',
    'https://pubmed.ncbi.nlm.nih.gov/31297483/');

  add('fma',
    'Fugl-Meyer Türkiye’de inme araştırmalarında karşılaştırma ölçütü olarak kullanılmaktadır; 2026 Türkçe SULCS çalışmasında Fugl-Meyer ile güçlü yakınsak geçerlilik ilişkisi bildirilmiştir. Bu çalışma FMA’nın kendi Türkçe çeviri validasyonu değildir; FTR Akademi doğrudan Türkçe FMA validasyonu doğrulanmış gibi etiketlemez.',
    'PubMed — Turkish SULCS validation using Fugl-Meyer as comparator',
    'https://pubmed.ncbi.nlm.nih.gov/41500923/');

  add('rivermead',
    'Rivermead Mobility Index Türkiye’de inme çalışmalarında yapı/yakınsak geçerlilik karşılaştırıcısı olarak kullanılmaktadır. Türkçe Trunk Impairment Scale çalışmasında RMI ile anlamlı ilişkiler; Türkçe Stroke Activity Scale çalışmasında RMI ile güçlü yakınsak ilişki bildirilmiştir. Bunlar RMI için bağımsız Türkçe çeviri validasyonu değildir.',
    'PubMed — Turkish stroke study using RMI as convergent measure',
    'https://pubmed.ncbi.nlm.nih.gov/31297483/');
  byId.rivermead.sources.push(['PubMed — Turkish Stroke Activity Scale validation using RMI','https://pubmed.ncbi.nlm.nih.gov/38536807/']);

  add('berg',
    'Türkçe Berg Denge Ölçeği 65 yaş üzeri sağlıklı Türk erişkinlerde doğrulanmıştır; toplam skor için test-tekrar test ICC 0.98, gözlemci içi ICC 0.98 ve gözlemciler arası ICC 0.97 bildirilmiştir. Bu çalışma yaşlı erişkin popülasyonuna özgüdür.',
    'PubMed — Turkish Berg Balance Scale validation',
    'https://pubmed.ncbi.nlm.nih.gov/18489806/');

  add('mas',
    'Türkiye’de post-inme dirsek fleksör tonusunun değerlendirilmesinde MAS/MMAS gözlemciler arası güvenilirliği incelenmiş; ayrıca Türkiye’de spinal kord yaralanmalı hastalarda MAS ve Modified Tardieu güvenilirliği birlikte araştırılmıştır. Bunlar “Türkçe form lisansı” değil, Türkiye klinik örneklemlerindeki ölçüm güvenilirliği kanıtıdır.',
    'PubMed — MAS/MMAS post-stroke reliability, Turkey',
    'https://pubmed.ncbi.nlm.nih.gov/20671560/');
  byId.mas.sources.push(['PubMed — MAS + Modified Tardieu reliability in SCI, Turkey','https://pubmed.ncbi.nlm.nih.gov/28485384/']);

  add('tardieu',
    'Modified Tardieu Scale, Türkiye’de spinal kord yaralanmalı hastalarda MAS ile birlikte gözlemciler arası ve gözlemci içi güvenilirlik açısından incelenmiştir. Bu veri ölçeğin Türkçe telif/çeviri hakkını değil, Türkiye klinik örneklemindeki ölçüm güvenilirliğini destekler.',
    'PubMed — Modified Tardieu reliability in SCI, Turkey',
    'https://pubmed.ncbi.nlm.nih.gov/28485384/');

  add('penn',
    'Penn Spasm Frequency Scale Türkiye’de spinal kord yaralanması araştırmalarında karşılaştırma ölçütü olarak kullanılmıştır; Türkçe SCI-SETT kültürler arası uyarlama çalışmasında PSFS yakınsak geçerlilik analizine dahil edilmiştir. Bu kanıt PSFS için bağımsız bir Türkçe form validasyonu değildir.',
    'PubMed — Turkish SCI-SETT study using Penn Spasm Frequency Scale',
    'https://pubmed.ncbi.nlm.nih.gov/28225536/');

  add('tug',
    'Timed Up and Go dil bağımlı bir anket değildir. Türkiye’de toplumda yaşayan yaşlı bireylerde hem gözlemci içi hem gözlemciler arası güvenilirliği doğrudan incelenmiş; TUG için gözlemci içi ICC 0.962 ve gözlemciler arası ICC 0.995 bildirilmiştir. Ayrıca Türk yaşlılarda düşme ayrımı çalışmalarında TUG kullanılmıştır; eşikler popülasyona özgü ele alınır.',
    'PubMed — TUG inter/intraobserver reliability in Turkish community-dwelling older adults',
    'https://pubmed.ncbi.nlm.nih.gov/39297511/');
  byId.tug.sources.push(['PubMed — TUG and fall discrimination in Turkish community-dwelling older adults','https://pubmed.ncbi.nlm.nih.gov/35303710/']);

  add('tinetti',
    'Performance-Oriented Mobility Assessment I (POMA-I/Tinetti) Türkçeye çevrilmiş ve 65 yaş üzeri Türk bireylerde kültürler arası uyarlama, iç tutarlılık, test-tekrar test ile gözlemciler arası/gözlemci içi güvenilirlik ve yapı geçerliliği incelenmiştir. Çalışmadaki POMA-I sürümü 28 puanlık denge+yürüme yapısıdır; diğer Tinetti/POMA varyantları bununla otomatik olarak eşitlenmez.',
    'Springer — Turkish POMA-I validity/reliability',
    'https://doi.org/10.1007/s11556-012-0096-2');

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

  add('jebsen',
    'Hacettepe Üniversitesi araştırmacıları Jebsen-Taylor El Fonksiyon Testi’ni 162 sağlıklı birey ve 143 el yaralanmalı hastada incelemiş; alt testler ve toplam skor için genel olarak iyi–mükemmel test-tekrar test güvenilirliği ve el yaralanmalarını ayırmaya yönelik cut-off analizi bildirmiştir. Bu çalışma Türkiye örneklem kanıtıdır.',
    'PubMed — Jebsen-Taylor psychometrics, Hacettepe/Turkey',
    'https://pubmed.ncbi.nlm.nih.gov/32156578/');

  add('9hpt',
    'Nine-Hole Peg Test Türkiye’de farklı Türk klinik araştırmalarında karşılaştırıcı motor beceri ölçütü olarak kullanılmaktadır. Örneğin Parkinson hastalarında Türkçe Comprehensive Coordination Scale validasyonunda 9-HPT yakınsak geçerlilik ölçütlerinden biridir; romatoid artritte Türkçe ABILHAND çalışmasında da NHPT kullanılmıştır. Bunlar 9-HPT’nin kendisi için bağımsız Türkçe norm/validasyon çalışması değildir.',
    'PubMed — Turkish Parkinson coordination-scale study using 9-HPT',
    'https://pubmed.ncbi.nlm.nih.gov/39059284/');
  byId['9hpt'].sources.push(['PubMed — Turkish ABILHAND-RA study using NHPT','https://pubmed.ncbi.nlm.nih.gov/32010888/']);

  add('purdue',
    'Hacettepe Üniversitesi örnekleminde Purdue Pegboard Testi’nin el yaralanmalı hastalarda yapı geçerliliği ve ayırt edici cut-off değerleri incelenmiştir. Bu çalışma standardize cihaz/protokol gereksinimini veya ticari materyal haklarını ortadan kaldırmaz.',
    'PubMed — Purdue Pegboard validity/cut-offs, Hacettepe/Turkey',
    'https://pubmed.ncbi.nlm.nih.gov/40337111/');

  add('sf36',
    'SF-36’nın Türkçe sürümünde Türkiye’de kanser hastalarında güvenilirlik ve yapı geçerliliği incelenmiş; sekiz alt ölçek için iç tutarlılık ve test-tekrar test stabilitesi desteklenmiştir. Ayrıca SF-36v2 Türkçe sürümü kas-iskelet patolojili örneklemde kültürler arası uyarlanıp ölçüm özellikleri değerlendirilmiştir. SF-36, SF-36v2 ve RAND-36 hak/puanlama sistemleri birbirine karıştırılmaz.',
    'PubMed — Turkish SF-36 reliability/construct validity in cancer',
    'https://pubmed.ncbi.nlm.nih.gov/15789959/');
  byId.sf36.sources.push(['PubMed — Turkish SF-36v2 musculoskeletal validation','https://pubmed.ncbi.nlm.nih.gov/27866914/']);

  add('mmse',
    'Standardize Mini Mental Test Türk toplumunda hafif demans ayrımında incelenmiş; eğitimli örneklemde 23/24 kesimi yüksek duyarlılık/özgüllük göstermiştir. Daha sonraki Türk çalışmaları yaş ve eğitim etkisini vurguladığından tek cut-off evrensel kabul edilmez.',
    'PubMed — Turkish standardized MMSE validation',
    'https://pubmed.ncbi.nlm.nih.gov/12794644/');
  byId.mmse.sources.push(['PubMed — Revised Turkish MMSE educated/uneducated older adults','https://pubmed.ncbi.nlm.nih.gov/19337986/']);
  byId.mmse.sources.push(['PubMed — Turkish MMSE normative psychometric caution','https://pubmed.ncbi.nlm.nih.gov/15729101/']);

  add('6mwt',
    '6 Dakika Yürüme Testi dil bağımlı bir anket değildir; Türkiye kanıtı burada “Türkçe form validasyonu” olarak değil popülasyona özgü referans veri olarak tutulur. Sağlıklı Türk çocuklarda 6–12 yaş ve ayrıca 11–18 yaş gruplarında 6 dakika yürüme mesafesi için ülkeye özgü referans değer/denklemleri yayımlanmıştır. Bu pediatrik referanslar erişkin, kardiyopulmoner veya nörolojik popülasyonlara genellenmez.',
    'PubMed — 6MWT reference values in healthy Turkish children 6–12 years',
    'https://pubmed.ncbi.nlm.nih.gov/31294244/');
  byId['6mwt'].sources.push(['PubMed — 6MWT reference values in healthy Turkish children/adolescents 11–18 years','https://pubmed.ncbi.nlm.nih.gov/24987154/']);

  db.turkishEvidenceVersion = '2026-09-03-pubmed-pass-3';
  db.turkishEvidencePolicy = {
    populationNamed: true,
    editionNamed: true,
    psychometricValidationDoesNotGrantCopyright: true,
    noUniversalCutoffInference: true,
    turkeyCohortEvidenceSeparatedFromTranslationLicense: true,
    languageValidationSeparatedFromPopulationReferenceValues: true,
    indirectComparatorEvidenceExplicitlyLabeled: true
  };
})();
