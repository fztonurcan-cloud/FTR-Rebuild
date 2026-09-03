(() => {
  'use strict';
  const db = window.FTR_CLINICAL_SCALES;
  if (!db || !Array.isArray(db.scales)) throw new Error('Clinical scales data missing before scoring evidence');
  const byId = Object.fromEntries(db.scales.map(scale => [scale.id, scale]));

  function patch(id, values) {
    const scale = byId[id];
    if (!scale) throw new Error(`Scoring evidence target missing: ${id}`);
    Object.assign(scale, values);
  }

  patch('fma', {
    scoringArchitecture: [
      'Motor alan: üst ekstremite maksimum 66 + alt ekstremite maksimum 34 = motor toplam 100.',
      'Tam FMA ayrıca duyu, denge, eklem hareket açıklığı ve eklem ağrısı alanlarını içerir; motor skor ile tam FMA skoru aynı şey değildir.',
      'Motor maddeler standart FMA mantığında 0–1–2 biçiminde derecelendirilir; resmi protokol/manuel kullanılmalıdır.'
    ],
    interpretation: 'Daha yüksek skor daha az sensorimotor bozukluğu gösterir. FTR Akademi motor-100 bilgisini tam FMA toplamıymış gibi sunmaz. Resmi FMA-UE/FMA-LE protokolleri ve 2026 uluslararası standardize manuel esas alınır.',
    sources: [
      ...byId.fma.sources,
      ['University of Gothenburg — Fugl-Meyer Assessment','https://www.gu.se/en/neuroscience-physiology/fugl-meyer-assessment']
    ]
  });

  patch('nihss', {
    scoringArchitecture: [
      'Akut nörolojik muayene, standart sırayla uygulanan 11 nörolojik alan içinde 15 puanlanan alt bileşen içerir.',
      'Standart toplam skor 0–42 aralığındadır; daha yüksek değer daha fazla nörolojik defisiti temsil eder.',
      'NINDS talimatı: maddeleri sırayla uygula, her kategori sonrası skoru kaydet, önceki skorlara geri dönüp değiştirme ve hastanın yaptığı performansı puanla.'
    ],
    interpretation: 'NIHSS akut inme şiddetinin standartlaştırılmış klinik ölçümüdür; tek başına tanı, damar görüntüleme veya tedavi uygunluğu kararı değildir. Şiddet sınıfları kullanılırsa kullanılan kaynak/protokol açıkça belirtilmelidir.',
    sources: [
      ...byId.nihss.sources,
      ['NINDS — NIH Stroke Scale instructions (2024)','https://www.ninds.nih.gov/sites/default/files/documents/NIH-Stroke-Scale_updatedFeb2024_508.pdf']
    ]
  });

  patch('odi', {
    scoringArchitecture: [
      'ODI bel ağrısına bağlı özürlülüğü 10 yaşam alanında değerlendirir.',
      'Sonuç yaygın olarak yüzdelik özürlülük skoru biçiminde raporlanır; eksik madde ve sürüm kuralları resmi ODI talimatına göre ele alınmalıdır.',
      'Elektronik formun görünümü, navigasyonu ve target-language ekranları lisans/e-version koşullarına tabidir.'
    ],
    interpretation: 'ODI yüzdesi kullanılan resmi sürüm ve eksik-madde kuralı belirtilmeden yorumlanmaz. FTR Akademi tam soru metnini veya lisanslı elektronik formu izinsiz yeniden üretmez.',
    sources: [
      ...byId.odi.sources,
      ['Mapi ePROVIDE — Official ODI','https://eprovide.mapi-trust.org/instruments/oswestry-disability-index']
    ]
  });

  patch('ndi', {
    scoringArchitecture: [
      'NDI, boyun ağrısının günlük yaşam üzerindeki etkisini 10 bölümde değerlendiren hasta-bildirimli bir indekstir.',
      'Elektronik uygulamada resmi sürüm, dil ve e-version konfigürasyonu korunmalıdır.',
      'Ticari/IT kullanımında Mapi/ölçek sahibi koşulları ve gerekli ekran incelemeleri dikkate alınır.'
    ],
    interpretation: 'NDI skoru resmi sürüm ve popülasyon bağlamında yorumlanır; farklı yayınlardaki kategori/cut-off değerleri evrensel kabul edilmez.',
    sources: [
      ...byId.ndi.sources,
      ['Mapi ePROVIDE — Official NDI','https://eprovide.mapi-trust.org/instruments/neck-disability-index']
    ]
  });

  patch('dash', {
    scoringArchitecture: [
      'Ana DASH disability/symptom bölümü 30 maddeden oluşur ve maddeler 1–5 puanlanır.',
      'Work ve Sport/Music modülleri isteğe bağlı 4’er maddelik ayrı modüllerdir ve ana DASH skorundan ayrı değerlendirilir.',
      'QuickDASH 11 maddelik ayrı kısa formdur; DASH ile aynı form gibi gösterilmez.'
    ],
    interpretation: 'DASH işlev ve semptom yükünü izlemek için kullanılır. FTR Akademi yalnız eğitimsel skor mimarisini açıklar; ticari ürün içine resmi form gömülmesi yazılı lisans gerektirir.',
    sources: [
      ...byId.dash.sources,
      ['Institute for Work & Health — DASH scoring instructions','https://www.dash.iwh.on.ca/scoring-instructions'],
      ['Institute for Work & Health — DASH overview','https://www.dash.iwh.on.ca/dash']
    ]
  });

  patch('womac', {
    scoringArchitecture: [
      'WOMAC 24 maddelik bir öz-bildirim ölçümüdür: ağrı 5, sertlik 2, fiziksel fonksiyon 17 madde.',
      'Likert, VAS ve NRS gibi farklı sunum biçimleri bulunabilir; sürüm ve ölçekleme biçimi sonuçla birlikte belirtilmelidir.',
      'Alt ölçekler ve toplam skor farklı yayınlarda farklı yön/ölçek dönüşümleriyle sunulabildiği için kullanılan resmi sürüm belgelenir.'
    ],
    duration: 'Yaklaşık 12 dk (RehabMeasures kaydı).',
    interpretation: 'Ağrı, sertlik ve fiziksel fonksiyon alt alanları ayrı izlenebilir. FTR Akademi farklı WOMAC sürümlerini ve ölçek dönüşümlerini tek bir evrensel puanlama gibi birleştirmez.',
    sources: [
      ...byId.womac.sources,
      ['WOMAC official — WOMAC 3.1','https://www.womac.com/womac/'],
      ['RehabMeasures — WOMAC','https://www.sralab.org/rehabilitation-measures/western-ontario-and-mcmaster-universities-osteoarthritis-index']
    ]
  });

  patch('hhs', {
    scoringArchitecture: [
      'Toplam maksimum 100 puan: ağrı 44, fonksiyon 47, deformite yokluğu 4, eklem hareket açıklığı 5.',
      'Fonksiyon alanı günlük yaşam aktiviteleri 14 puan + yürüyüş 33 puan bileşenlerini içerir.',
      'Modified Harris Hip Score (mHHS), klinisyen tarafından ölçülen deformite/ROM bileşenlerini dışarıda bırakan farklı bir türevdir; HHS ile aynı skor gibi sunulmaz.'
    ],
    duration: 'Yaklaşık 5 dk (literatür özeti).',
    interpretation: 'Daha yüksek skor daha iyi kalça durumunu gösterir. Geleneksel kategori sınırları gösterilecekse kaynakla etiketlenir; total HHS ve mHHS açık biçimde ayrılır.',
    sources: [
      ...byId.hhs.sources,
      ['Arthritis Care & Research — HHS measurement review','https://acrjournals.onlinelibrary.wiley.com/doi/10.1002/acr.20549']
    ]
  });

  patch('gmfm', {
    scoringArchitecture: [
      'GMFM-88: 88 madde, beş boyut — yatma/yuvarlanma; oturma; emekleme/dizüstü; ayakta durma; yürüme/koşma/zıplama.',
      'Madde puanı GMFM-88 ve GMFM-66 için 0,1,2,3 veya Not Tested olarak kaydedilir: 0 başlatmaz, 1 başlatır, 2 kısmen tamamlar, 3 tamamlar.',
      'GMFM-88’de boyut yüzdeleri hesaplanır ve beş boyutun yüzdeleri ortalanarak toplam elde edilir; test edilmeyen maddeler GMFM-88 hesabında 0 kabul edilir.',
      'GMFM-66, Rasch ile seçilmiş 66 maddelik tek-boyutlu interval ölçektir ve toplam skor GMAE yazılımı/algoritması ile hesaplanır; basit ham puan toplamı değildir.'
    ],
    duration: 'GMFM-88 yaklaşık 45–60 dk; GMFM-66 daha kısa olabilir. Abbreviated uygulamalar ayrıca tanımlıdır.',
    interpretation: 'GMFM-66 skoru 0–100 interval ölçekte ve standart hata/%95 GA ile raporlanabilir. GMFM-88 yüzde toplamı ile GMFM-66 GMAE skoru birbirine dönüştürülmez.',
    sources: [
      ...byId.gmfm.sources,
      ['CanChild — GMFM','https://canchild.ca/resources/44-gross-motor-function-measure-gmfm/'],
      ['CanChild — GMFM scoring','https://canchild.ca/resources/321-gmfm-scoring/'],
      ['CanChild — GMFM App+','https://canchild.ca/shop/38-the-gross-motor-function-measure-app/']
    ]
  });

  patch('gmfcs', {
    scoringArchitecture: [
      'GMFCS E&R beş seviyeli bir sınıflandırmadır; test toplam puanı değildir.',
      'Sınıflandırma oturma, yürüme ve tekerlekli mobilite dahil kişinin kendi başlattığı günlük kaba motor işlevine dayanır.',
      'Seviye tanımları yaş bandına göre değişir; yaşa uygun resmi tanımlayıcı kullanılmalıdır.'
    ],
    interpretation: 'Seviye I en bağımsız kaba motor işlevi, Seviye V en fazla destek gereksinimini temsil eder; GMFCS değişime duyarlı tedavi sonucu puanı yerine fonksiyonel sınıflandırma olarak kullanılır.',
    sources: [
      ...byId.gmfcs.sources,
      ['CanChild — GMFCS information','https://canchild.ca/diagnoses/cerebral-palsy/gross-motor-function-classification-system-expanded-revised-gmfcs-er/']
    ]
  });

  patch('jebsen', {
    scoringArchitecture: [
      'Yedi simüle günlük yaşam el görevi her el için ayrı zamanlanır.',
      'Alt test skoru görevi tamamlama süresidir (saniye); daha kısa süre daha iyi performansı gösterir.',
      'RehabMeasures özetinde her alt test için en fazla 120 sn ve dominant olmayan elin önce uygulanması belirtilir.'
    ],
    interpretation: 'Toplam süre ve alt test süreleri yaş, el dominansı, tanı ve kullanılan standardize ekipman bağlamında yorumlanır; norm tabloları kaynağı belirtilmeden genellenmez.',
    sources: [
      ...byId.jebsen.sources,
      ['RehabMeasures — Jebsen-Taylor Hand Function Test','https://www.sralab.org/rehabilitation-measures/jebsen-taylor-hand-function-test']
    ]
  });

  patch('purdue', {
    scoringArchitecture: [
      'Standart bataryalar: Sağ El 30 sn, Sol El 30 sn, İki El 30 sn, bu üç skorun matematiksel toplamı ve Montaj 60 sn.',
      'Tek-el/iki-el bölümlerinde yerleştirilen peg sayısı, montajda tamamlanan montaj bileşenleri/protokol skoru kullanılır.',
      'Standardize Purdue Pegboard cihazı, pinler, yakalar ve pullar gerekir.'
    ],
    duration: 'Talimat dahil yaklaşık 5–10 dk.',
    interpretation: 'El dominansı, yaş, tanı ve norm seti sonuç yorumunda belirtilmelidir. FTR Akademi ticari cihaz/protokol materyalini çoğaltmaz.',
    sources: [
      ...byId.purdue.sources,
      ['RehabMeasures — Purdue Pegboard Test','https://www.sralab.org/rehabilitation-measures/purdue-pegboard-test']
    ]
  });

  patch('sf36', {
    scoringArchitecture: [
      'SF-36 ailesi sekiz sağlık alanı üretir: fiziksel fonksiyon, fiziksel role bağlı kısıtlılık, bedensel ağrı, genel sağlık, vitalite, sosyal fonksiyon, emosyonel role bağlı kısıtlılık ve mental sağlık.',
      'SF-36v2 lisanslı QualityMetric/IQVIA ürünüdür; RAND-36 benzer maddeler içeren fakat kullanım/puanlama hakları farklı ayrı bir araçtır.',
      'Fiziksel ve mental bileşen özetleri (PCS/MCS) standart norm-temelli algoritmalara bağlıdır; basit sekiz-alt-ölçek ortalaması değildir.'
    ],
    interpretation: 'Daha yüksek alt ölçek skorları genel olarak daha iyi sağlık durumunu temsil eder; ancak v1/v2, RAND-36, norm seti ve skor algoritması sonuçla birlikte tanımlanmalıdır.',
    sources: [
      ...byId.sf36.sources,
      ['IQVIA QualityMetric — SF Health Surveys','https://www.iqvia.com/locations/united-states/solutions/technologies/qualitymetric'],
      ['RAND — 36-Item Health Survey','https://www.rand.org/health-care/surveys_tools/mos/36-item-short-form.html']
    ]
  });

  patch('mmse', {
    scoringArchitecture: [
      'Orijinal MMSE ve MMSE-2 Standard Version 30 puanlık bilişsel tarama yapısını kullanır.',
      'MMSE-2: Brief Version 16 puandır; Expanded Version daha uzun bir sürümdür. Sürüm adı sonuçla birlikte belirtilmelidir.',
      'Oryantasyon, kayıt/hatırlama, dikkat-hesaplama, dil ve görsel-konstrüktif alanları taranır; tam telifli madde metni FTR Akademi’ye kopyalanmaz.'
    ],
    interpretation: 'Sonuç bilişsel taramadır, demans tanısı değildir. Eğitim, yaş, dil, kültür ve kullanılan Türkçe norm/cut-off çalışması yorumda görünür tutulur.',
    sources: [
      ...byId.mmse.sources,
      ['PAR — MMSE-2','https://www.parinc.com/products/MMSE-2'],
      ['PAR — permissions/licensing','https://www.parinc.com/about/connect-with-us/licensing-team/available-par-products']
    ]
  });

  patch('6mwt', {
    scoringArchitecture: [
      'Tek temel sonuç, 6 dakikada yürünülen toplam mesafedir (metre).',
      'Katılımcı ayakta dinlenebilir; zamanlayıcı durmaz. Dinlenme sayısı/süresi ve yardımcı cihaz kaydedilir.',
      'Parkur uzunluğu sonucu etkiler. ATS klasik standardı 30 m koridoru önerirken farklı klinik protokoller 12/14/34 m parkurlar kullanabilir; seri ölçümde aynı protokol korunmalıdır.'
    ],
    interpretation: 'Mesafe tek başına hastalık şiddeti sınıfı değildir. Norm, MDC/MCID ve beklenen değerler tanı, yaş, cinsiyet, boy/kilo ve kullanılan parkura göre kaynaklandırılır.',
    sources: [
      ...byId['6mwt'].sources,
      ['RehabMeasures — 6 Minute Walk Test','https://www.sralab.org/rehabilitation-measures/6-minute-walk-test']
    ]
  });

  db.scoringEvidenceVersion = '2026-09-03-deep-scoring-pass-1';
  db.scoringEvidencePolicy = {
    protectedItemWordingExcluded: true,
    editionSpecificScoring: true,
    subscaleArchitectureExposed: true,
    normsAndCutoffsRequirePopulationSource: true,
    classificationVersusOutcomeSeparated: true
  };
})();
