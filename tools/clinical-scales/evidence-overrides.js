(() => {
  'use strict';
  const db = window.FTR_CLINICAL_SCALES;
  if (!db || !Array.isArray(db.scales)) throw new Error('Clinical scales data missing before evidence overrides');

  const byId = Object.fromEntries(db.scales.map(scale => [scale.id, scale]));
  const patch = (id, values) => {
    const scale = byId[id];
    if (!scale) throw new Error(`Evidence override target missing: ${id}`);
    Object.assign(scale, values);
  };

  patch('barthel', {
    duration: 'Doğrudan gözlem yaklaşık 20 dk; öz-bildirim uygulaması yaklaşık 2–5 dk sürebilir.',
    equipment: 'Kalem ve değerlendirme formu yeterlidir; doğrudan performans gözleminde gerçek GYA ortamı kullanılabilir.',
    evidenceNote: 'RehabMeasures 2025 güncellemesi; ticari/IT kullanımı için Mapi koşulları ayrıca kontrol edilir.',
    evidenceDate: '2026-09-03'
  });

  patch('fim', {
    duration: 'Yaklaşık 30–45 dk.',
    evidenceNote: '18 madde: 13 motor + 5 bilişsel; 1–7/madde; 18–126 toplam. FIM lisanslıdır.',
    evidenceDate: '2026-09-03'
  });

  patch('rivermead', {
    format: '15 madde: 14 öz-bildirim + 1 doğrudan gözlem. Her madde 0/1; toplam 0–15. Daha yüksek skor daha iyi mobiliteyi gösterir.',
    duration: 'Yaklaşık 3–5 dk.',
    evidenceNote: 'RehabMeasures güncel kaydı; NINDS CDE telif bildirimi ayrıca korunur.',
    evidenceDate: '2026-09-03'
  });

  patch('mas', {
    format: '0, 1, 1+, 2, 3, 4 dereceleri. Pasif hareket tekniği ve yaklaşık bir saniyelik hızlı hareket standardizasyonun parçasıdır.',
    evidenceNote: 'Bohannon & Smith temelli Modified Ashworth talimatı; skor yalnız artmış pasif harekete direnci dereceler.',
    evidenceDate: '2026-09-03'
  });

  patch('tardieu', {
    format: 'Kas yanıt kalitesi + yakalama açısı birlikte kaydedilir. V1 mümkün olduğunca yavaş, V2 yerçekimi hızı, V3 mümkün olduğunca hızlıdır; R1 hızlı gerimde yakalama açısı, R2 yavaş gerimde tam pasif ROM olarak kaydedilir.',
    equipment: 'Gonyometre; test edilen ekleme uygun pozisyonlama alanı.',
    interpretation: 'R2−R1 farkı dinamik ton bileşenini anlamaya yardımcı olabilir. Kullanılan Tardieu/MTS sürümü ve reaksiyon kalite dereceleri açıkça belirtilmelidir.',
    evidenceNote: 'RehabMeasures Modified Tardieu açıklaması.',
    evidenceDate: '2026-09-03'
  });

  patch('penn', {
    format: 'İki parçalı öz-bildirim: spazm sıklığı 0–4, spazm şiddeti 1–3. Sıklık 0 ise şiddet bölümü uygulanmaz.',
    duration: 'Yaklaşık 1 dk.',
    evidenceNote: 'RehabMeasures Penn Spasm Frequency Scale.',
    evidenceDate: '2026-09-03'
  });

  patch('berg', {
    format: '14 performans görevi; her madde 0–4; toplam 0–56.',
    interpretation: '56 fonksiyonel dengeyi temsil eder. <45 eşiği bazı yaşlı örneklemlerde daha yüksek düşme riski ile ilişkilidir; inme ve diğer popülasyonlarda farklı cut-off değerleri bildirilmiştir. Uygulama popülasyonu belirtmeden tek eşik göstermez.',
    evidenceNote: 'RehabMeasures BBS kaydı public-domain erişimi ve popülasyona özgü cut-off verilerini belirtir.',
    evidenceDate: '2026-09-03'
  });

  patch('tug', {
    format: 'Standart kolçaklı sandalyeden kalk → 3 m normal hızda yürü → dön → geri yürü → otur. Süre “başla/go” komutunda başlar ve kişi yeniden oturduğunda biter.',
    duration: 'Genellikle 3 dakikadan kısa.',
    equipment: 'Standart kolçaklı sandalye, 3 m işaretli düz yürüyüş hattı ve kronometre.',
    interpretation: 'CDC STEADI, yaşlı düşme taramasında ≥12 sn sonucunu risk işareti olarak kullanır. Bu eşik tüm tanı ve yaş grupları için evrensel değildir; seri ölçümlerde aynı yardımcı cihaz kullanılmalıdır.',
    evidenceNote: 'CDC STEADI + RehabMeasures.',
    evidenceDate: '2026-09-03'
  });

  patch('tinetti', {
    format: 'Uygulamada açıkça 16 maddelik / 28 puanlık POMA sürümü kullanılır: 9 denge maddesi + 7 yürüyüş maddesi.',
    equipment: 'Sert kolçaksız sandalye, kronometre/saat ve yaklaşık 4.57 m (15 ft) yürüyüş alanı.',
    duration: 'Yaklaşık 10–15 dk.',
    evidenceNote: 'RehabMeasures POMA; farklı POMA sürümleri bulunduğu için sürüm etiketi zorunludur.',
    evidenceDate: '2026-09-03'
  });

  patch('dgi', {
    evidenceNote: 'Sekiz dinamik yürüyüş görevi ve 24 puanlık yapı sürüm etiketiyle sunulur; popülasyona özgü yorum gerekir.',
    evidenceDate: '2026-09-03'
  });

  patch('dash', {
    rights: {
      mode: 'restricted',
      label: 'Ticari lisans gerekli',
      note: 'DASH/QuickDASH telifi Institute for Work & Health’a aittir. Satılan bir ürün veya ticari yazılım/web yazılımına gömme, önceden yazılı ticari lisans gerektirir; madde metni değiştirilemez.'
    },
    evidenceNote: 'Institute for Work & Health resmi lisans ve Conditions of Use sayfaları.',
    evidenceDate: '2026-09-03'
  });

  patch('fma', {
    evidenceNote: 'University of Gothenburg protokolleri klinik/araştırmada ticari olmayan kullanım için ücretsizdir; resmi çeviri için izin gerekir. 2026 uluslararası standardize manuel ayrıca yayımlanmıştır.',
    evidenceDate: '2026-09-03'
  });

  patch('gmfm', {
    rights: {
      mode: 'restricted',
      label: 'McMaster/CanChild izni',
      note: 'GMFM ölçümü McMaster’ın fikri mülkiyetidir. CanChild lisansı kişisel klinik/araştırma ve ticari olmayan kullanımla sınırlıdır; ölçümü ticari ürüne bileşen olarak ekleme izinsiz yapılamaz.'
    },
    evidenceNote: 'CanChild GMFM App+ lisans metni.',
    evidenceDate: '2026-09-03'
  });

  patch('pdms', {
    name: 'Peabody Gelişimsel Motor Ölçekleri (PDMS)',
    short: 'PDMS',
    population: 'Erken çocukluk dönemi. Güncel ticari PDMS-3 sürümünün yaş aralığı 0–5 yıldır.',
    domains: ['Vücut Kontrolü','Vücut Taşıma','Nesne Kontrolü','El Manipülasyonu','El-Göz Koordinasyonu','Fiziksel Uygunluk (ek alt test)'],
    format: 'Güncel PDMS-3 beş çekirdek alt test ve bir ek Fiziksel Uygunluk alt testinden oluşur. Yaş eşdeğerleri, persentiller, alt-test ölçekli skorları ve Gross/Fine/Total Motor indeksleri üretir.',
    duration: 'PDMS-3 yaklaşık 60–90 dk.',
    equipment: 'Standart PDMS-3 materyal/obje kiti ve kayıt materyalleri gerekir.',
    interpretation: 'PDMS-2 ve PDMS-3 maddeleri, normları ve skor sistemleri karıştırılmaz. PDMS-3 standart skorları Pearson’ın resmi online puanlama sistemi üzerinden hesaplanır.',
    rights: {
      mode: 'restricted',
      label: 'Ticari test — bilgi modu',
      note: 'PDMS-3 Pearson tarafından satılan, Qualification Level B gerektiren standart bir değerlendirmedir. Resmi maddeler, norm tabloları veya puanlama sistemi FTR Akademi içinde çoğaltılmaz.'
    },
    evidenceNote: 'Pearson Assessments PDMS-3 ürün bilgisi, Mayıs 2023.',
    evidenceDate: '2026-09-03',
    sources: [
      ['Pearson Assessments — PDMS-3','https://www.pearsonassessments.com/store/en/usd/p/P100049000.html']
    ]
  });

  patch('jebsen', {
    format: 'Her iki elde ayrı uygulanan 7 zamanlı işlevsel alt test; çoğu uygulamada dominant olmayan el önce test edilir ve alt test skorları saniye cinsindendir.',
    duration: 'Yaklaşık 15–45 dk.',
    evidenceNote: 'RehabMeasures Jebsen–Taylor güncel özeti; standardize materyal gereksinimleri korunur.',
    evidenceDate: '2026-09-03'
  });

  patch('9hpt', {
    format: 'Tek test eliyle 9 peg tek tek deliklere yerleştirilir, ardından tek tek çıkarılıp kaba geri konur. Skor toplam süredir (saniye).',
    duration: 'Yaklaşık 1–3 dk.',
    equipment: 'Standart 9 delikli pegboard, 9 peg, peg kabı ve kronometre.',
    interpretation: 'Pegboard geometrisi/norm seti değişirse sonuçlar karşılaştırılamayabilir; kullanılan ekipman standardize edilmelidir.',
    evidenceNote: 'RehabMeasures Nine-Hole Peg Test.',
    evidenceDate: '2026-09-03'
  });

  patch('sf36', {
    rights: {
      mode: 'restricted',
      label: 'SF-36v2 lisanslı',
      note: 'SF-36v2 QualityMetric/IQVIA lisans ekosistemindedir. RAND-36 ayrı bir araç/puanlama kaynağıdır ve uygulamada SF-36v2 ile aynı ürün gibi gösterilmez.'
    },
    evidenceNote: 'QualityMetric/IQVIA SF Health Survey lisans materyalleri.',
    evidenceDate: '2026-09-03'
  });

  patch('mmse', {
    format: 'Orijinal MMSE 30 puanlık bilişsel taramadır. MMSE-2 Standard Version da 30 puanlık yapıyı korurken sorunlu bazı maddeleri güncellemiştir.',
    duration: 'Orijinal MMSE yaklaşık 5–10 dk; MMSE-2 Standard Version yaklaşık 10–15 dk.',
    rights: {
      mode: 'restricted',
      label: 'PAR lisansı gerekli',
      note: 'MMSE/MMSE-2 materyalleri PAR tarafından ticari olarak dağıtılır. Türkçe dahil çeviri/uyarlamalar için resmi izin ve lisans koşulları korunur; tam madde metni uygulamaya kopyalanmaz.'
    },
    interpretation: 'Bilişsel tarama sonucudur, tanı değildir. Eğitim, dil, kültür ve kullanılan yerel norm/cut-off bağlamı açıkça belirtilmelidir.',
    evidenceNote: 'PAR MMSE ve MMSE-2 resmi ürün/lisans sayfaları.',
    evidenceDate: '2026-09-03'
  });

  patch('6mwt', {
    format: 'Kişi standartlaştırılmış düz parkurda 6 dakika boyunca kendi hızında mümkün olduğunca fazla mesafe yürür. Dinlenme yapılabilir ancak süre çalışmaya devam eder; dinlenme sayısı/süresi ve yardımcı cihaz kaydedilir.',
    duration: 'Yürüme süresi 6 dk; hazırlık ve kayıtla klinisyen zamanı genellikle 10 dk civarındadır.',
    equipment: 'Kronometre, sandalye, iki koni, işaretli düz yürüyüş parkuru, mesafe ölçümü; kardiyopulmoner uygulamalarda ilgili güvenlik/monitorizasyon ekipmanı.',
    interpretation: 'Sonuç 6 dakikada yürünen toplam mesafedir. Parkur uzunluğu sonucu etkileyebilir; seri karşılaştırmada aynı protokol/parkur kullanılmalıdır. ATS’nin klasik standardı yaklaşık 30 m koridor önerir.',
    evidenceNote: 'ATS 6MWT statement + RehabMeasures.',
    evidenceDate: '2026-09-03'
  });

  db.evidenceVersion = '2026-09-03-authoritative-pass-2';
  db.evidencePolicy = {
    populationSpecificCutoffs: true,
    exactEditionLabels: true,
    proprietaryFormsNotEmbeddedWithoutPermission: true,
    originalOfflineProcedureIllustrations: true
  };
})();
