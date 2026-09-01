# Hidran Jakarta — Usability Testing Plan

**Tim ON TIME**

> Aplikasi iOS untuk petugas Pemadam Kebakaran (Damkar) Jakarta yang merekomendasikan
> hidran siap-pakai terdekat dari titik kebakaran dan memberi navigasi langsung ke sana —
> bukan sekadar yang tampak paling dekat di peta.

| | |
|---|---|
| **Core Feature** | Rekomendasi & Navigasi Hidran |
| **Participants** | Petugas Damkar |
| **Platform** | iOS · SwiftUI + MapKit |

### Data dasar (dataset aktual)

| Total Hidran | Siap Pakai | Rusak | Wilayah Jakarta |
|:---:|:---:|:---:|:---:|
| **933** | **390** | **543** | **5** |

---

## 01 · Scenario

*Dalam kasus apa user harus mengakses core feature?*

Seorang petugas Satgas Damkar menerima panggilan kebakaran di sebuah lokasi di Jakarta.
Saat dalam perjalanan atau setibanya di lokasi, persediaan air di mobil pemadam menipis dan
petugas perlu **segera menemukan hidran yang benar-benar berfungsi dan paling cepat dijangkau**
dari titik kebakaran.

Tantangannya: lebih dari separuh hidran di lapangan (543 dari 933) berstatus rusak, jadi
memilih yang "terlihat paling dekat" di peta bisa berujung buntu. Dalam situasi darurat dan
waktu-kritis ini, petugas membuka aplikasi untuk menandai lokasi kebakaran dan langsung
memperoleh daftar hidran siap-pakai terurut berdasarkan waktu tempuh, lengkap dengan rute
menuju ke sana.

---

## 02 · Capabilities

*Apa saja yang bisa dilakukan aplikasi.*

- **Onboarding Petugas** — Menentukan peran (Satgas / Command Center) dan wilayah task force,
  dari lima wilayah Jakarta, sebelum masuk ke peta.
- **Peta & Filter Kondisi** — 933 titik hidran di atas peta (standar / satelit), dengan
  statistik Total · Siap · Rusak dan filter kondisi agar petugas fokus pada hidran yang berfungsi.
- **Buat Laporan Insiden** — Menandai lokasi kebakaran dengan menggeser peta ke pin tengah atau
  mencari alamat; dikunci passcode 4-digit untuk otorisasi Command Center. Beberapa laporan aktif
  dapat dikelola sekaligus.
- **Rekomendasi Cerdas** — Memeringkat hidran siap-pakai terdekat berdasarkan estimasi waktu
  tempuh berkendara (ETA), lalu jarak ke insiden — bukan sekadar garis lurus di peta.
  (8 kandidat terdekat → 5 rekomendasi teratas.)
- **Rute & Navigasi** — Menggambar rute mengemudi dari posisi petugas ke hidran terpilih, dan
  membuka Apple Maps untuk navigasi turn-by-turn dengan info lalu lintas.
- **Kelola Laporan** — Menelusuri, membuka kembali, dan mengakhiri laporan insiden. Menghapus
  laporan juga dikunci passcode dan membersihkan rekomendasi serta rute aktif.

---

## 03 · Core Feature Flow

*Apa yang harus dilakukan user agar berhasil memakai core feature? Per-action.*

### Fase A · Persiapan

1. **Buka aplikasi** — Petugas melihat peta Jakarta dengan sebaran hidran dan statistik kondisi
   (Total / Siap / Rusak) di bagian atas.
2. **Mulai laporan baru** `Tombol +` — Ketuk tombol "+" pada panel Laporan Insiden di bagian
   bawah layar.
3. **Masukkan kode otorisasi** — Ketik passcode 4-digit Command Center pada keypad di layar untuk
   membuka mode penempatan pin.

### Fase B · Menandai Insiden

4. **Tentukan lokasi kebakaran** — Geser peta agar pin merah di tengah tepat pada titik kebakaran,
   atau ketik alamat di kolom pencarian lalu pilih hasilnya untuk memusatkan peta.
5. **Konfirmasi lokasi** `Konfirmasi Lokasi` — Ketuk tombol konfirmasi. Aplikasi membuat laporan
   insiden dan mulai menghitung rekomendasi.
   → *Sistem mengevaluasi kandidat hidran terdekat.*

### Fase C · Rekomendasi & Navigasi

6. **Lihat rekomendasi hidran** — Kartu hidran siap-pakai muncul terurut (peringkat 1/5) dengan
   jarak dari insiden, jarak berkendara, dan estimasi waktu tempuh.
7. **Bandingkan antar-rekomendasi** `‹ ›` — Telusuri kartu dengan panah kiri/kanan. Peta ikut
   berpindah ke hidran terpilih dan menggambar rute dari posisi petugas.
   → *Rute mengemudi tergambar otomatis di peta.*
8. **Buka detail hidran** — Geser panel ke atas untuk melihat wilayah, kecamatan, kelurahan, dan
   alamat lengkap hidran.
9. **Mulai navigasi** `Navigasi via Apple Maps` — Ketuk tombol navigasi. Apple Maps terbuka dengan
   rute mengemudi menuju hidran terpilih.
   → *Petugas berangkat ke hidran — tugas inti selesai.*
10. **Akhiri laporan** — Setelah selesai, akhiri / hapus laporan (dikunci passcode) untuk
    membersihkan insiden, rekomendasi, dan rute aktif.

---

## 04 · Observation Points

*Hal-hal yang diamati saat sesi usability testing.*

- Apakah petugas **menemukan tombol "+"** untuk memulai laporan tanpa ragu?
- Apakah **passcode terasa menghambat** pada kondisi darurat waktu-kritis?
- Apakah cara **"geser peta ke pin tengah"** intuitif, atau petugas mengharap tap langsung?
- Apakah petugas paham dasar pemeringkatan adalah **ETA, bukan garis lurus**?
- Apakah transisi ke **Apple Maps terasa mulus** dan sesuai harapan?
- Apakah kartu rekomendasi **terbaca sekilas** saat petugas sedang bergerak?

---

*Hidran Jakarta · Tim ON TIME — Usability Testing Plan*
