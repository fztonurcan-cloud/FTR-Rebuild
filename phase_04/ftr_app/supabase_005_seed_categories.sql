insert into public.categories (slug, name, description, sort_order, is_active)
values
('temel-bilimler', 'Temel Bilimler', 'Anatomi, fizyoloji, patoloji ve temel tıp bilimleri.', 1, true),
('kinezyoloji-biyomekanik', 'Kinezyoloji & Biyomekanik', 'Hareket analizi, kinezyoloji ve biyomekanik.', 2, true),
('degerlendirme-muayene', 'Değerlendirme & Muayene', 'Fizyoterapi değerlendirme ve ölçüm yöntemleri.', 3, true),
('ortopedi-spor', 'Ortopedik & Spor Rehabilitasyon', 'Ortopedik ve spor yaralanmaları rehabilitasyonu.', 4, true),
('norolojik-rehabilitasyon', 'Nörolojik Rehabilitasyon', 'Nörolojik hastalıklar ve rehabilitasyon.', 5, true),
('kardiyopulmoner', 'Kardiyopulmoner Rehabilitasyon', 'Kardiyak ve pulmoner rehabilitasyon.', 6, true),
('pediatrik', 'Pediatrik Rehabilitasyon', 'Pediatrik fizyoterapi ve rehabilitasyon.', 7, true),
('ortez-protez', 'Ortez & Protez', 'Ortez, protez ve amputasyon rehabilitasyonu.', 8, true),
('fizik-tedavi-modaliteleri', 'Fizik Tedavi Modaliteleri', 'Elektroterapi ve fiziksel ajanlar.', 9, true),
('manuel-terapi', 'Manuel Terapi', 'Manuel terapi ve mobilizasyon yaklaşımları.', 10, true),
('egzersiz-kutuphanesi', 'Egzersiz Kütüphanesi', 'Bölgelere ve amaçlara göre egzersizler.', 11, true),
('klinik-acil', 'Klinik & Acil', 'Klinik durumlar, hastalıklar ve acil yaklaşımlar.', 12, true),
('sinav-kaynaklar', 'Sınav & Kaynaklar', 'Sınav ve yardımcı kaynak içerikleri.', 13, true)
on conflict (slug) do update set name=excluded.name, description=excluded.description, sort_order=excluded.sort_order, is_active=excluded.is_active;
