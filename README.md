# FTR Akademi v29.5 — LOCKED ROLLBACK CHECKPOINT

Bu branch yalnızca fiziksel telefonda doğrulanmış v29.5 rollback noktasını tanımlar.

## Canonical APK
- Dosya: `FTR-Akademi-v29.5-HAREKET-STUDYOSU-INSTALL-FIX.apk`
- Boyut: `1130840644` bayt
- SHA-256: `2518c9b79a69f2fe3c5a60b4b8c2a454bbe6fb2b83daad789374695e2e3fdbb3`
- Paket: `com.ftrakademi.preview3`
- Android imza: V1 + V2 doğrulandı
- Sertifika SHA-256: `8771cb32093de52d180d08270909fa5796850900bf7eecaf2b3181873c488be2`
- Sertifika subject: `CN=FTR Akademi Preview v41,OU=Preview,O=FTR Akademi,C=TR`

## Koruma kuralı
Bu branch üzerinde geliştirme yapılmaz. v29.5 dosyaları değiştirilmez, yeniden imzalanmaz ve üzerine yazılmaz. Yeni çalışma sürümleri ayrı branch/sürüm üzerinde ilerler.

## Neden APK repository içine doğrudan konmadı?
APK yaklaşık 1.13 GB olduğu için normal GitHub repository dosyası olarak tutulmaya uygun değildir. Rollback bütünlüğü SHA-256 manifesti ve deterministik parça birleştirme tarifiyle sabitlenmiştir.

## Parça manifesti
1. `FTR-Akademi-v29.4-HAREKET-STUDYOSU.apk.part00` — `66e4fde1e74959e864dbdfb949e6920d6a1c3a386d18b6999db9dd3c2539329e`
2. `FTR-Akademi-v29.4-HAREKET-STUDYOSU.apk.part01` — `c7513292164b9b44eafb500d46eb368483df565ed03ea7bc4fafadabf6977e1a`
3. `FTR-Akademi-v29.4-HAREKET-STUDYOSU.apk.part02` — `28121e6362678e8669ecad520e42e6918e5e54f34caca75ef5fb553271c6d518`
4. `FTR-Akademi-v29.4-HAREKET-STUDYOSU.apk.part03` — `652d49a5329e39105a37acbddc19f0bb7537fcb45275be4db07657005d0935b7`
5. `FTR-Akademi-v29.5-HAREKET-STUDYOSU-INSTALL-FIX.apk.part04` — `d72aca72f50ada272caa9d2930d8f9c9628a11ed768d5ea74a3cddb3f5a8e913`

Birleştirilen APK'nın SHA-256 değeri yukarıdaki canonical hash ile birebir eşleşmeden rollback geçerli kabul edilmez.
