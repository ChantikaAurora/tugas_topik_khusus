# Lost & Found Kampus

Aplikasi pencarian dan pelaporan barang hilang/temuan di lingkungan kampus/kos, dengan pencarian fuzzy dan auto-matching antara laporan "hilang" dan "temuan".

Proyek ini dibuat sebagai tugas UAS Topik Khusus, dengan fokus penerapan **MongoDB** (penyimpanan data fleksibel) dan **Elasticsearch** (fuzzy search & matching).

---

## Fitur

- Lapor barang hilang / barang ditemukan (judul, deskripsi, kategori, lokasi)
- Pencarian fuzzy & sinonim (contoh: "dompet coklat" bisa menemukan "dompet warna cokelat kulit")
- Auto-matching: sistem otomatis mencari laporan lawan jenis (hilang↔temuan) yang mirip setiap kali laporan baru dibuat
- Mobile app berbasis Flutter

---

## Tech Stack

| Komponen | Teknologi |
|---|---|
| Mobile UI | Flutter |
| Backend API | FastAPI (Python) |
| Database utama | MongoDB |
| Search & matching engine | Elasticsearch |

Arsitektur backend berupa **modular monolith**: satu aplikasi backend, dengan kode dipisah per modul (`database`, `es_client`, `models`, `routes`) — tanpa message queue atau microservices terpisah, supaya sederhana untuk skala proyek ini.

---

## Struktur Proyek

```
lostfound-backend/       # Backend API (FastAPI + MongoDB + Elasticsearch)
├── app/
│   ├── database.py      # Koneksi MongoDB
│   ├── es_client.py     # Koneksi Elasticsearch, search & matching logic
│   ├── models/report.py # Skema data laporan
│   ├── routes/report.py # Endpoint API
│   └── main.py           # Entry point
├── docker-compose.yml    # MongoDB + Elasticsearch (development lokal)
└── requirements.txt

lostfound_app/            # Mobile app (Flutter)
├── lib/
│   ├── models/report.dart
│   ├── services/          # API config & service call ke backend
│   ├── screens/           # Halaman buat laporan & pencarian
│   └── main.dart
└── pubspec.yaml
```

---

## Cara Menjalankan

### 1. Backend

```bash
cd lostfound-backend

# Jalankan MongoDB & Elasticsearch
docker compose up -d

# Buat virtual environment (sekali saja)
python3.10 -m venv venv
source venv/bin/activate

# Install dependency
pip install -r requirements.txt

# Jalankan server
uvicorn app.main:app --reload
```

Backend akan berjalan di `http://127.0.0.1:8000`. Dokumentasi API otomatis tersedia di `http://127.0.0.1:8000/docs` (Swagger UI).

### 2. Mobile App (Flutter)

```bash
cd lostfound_app
flutter pub get
```

Sebelum menjalankan, sesuaikan base URL API di `lib/services/api_config.dart` sesuai platform yang dipakai:

| Platform testing | Base URL |
|---|---|
| macOS Desktop | `http://127.0.0.1:8000` |
| iOS Simulator | `http://127.0.0.1:8000` |
| Android Emulator | `http://10.0.2.2:8000` |
| Device fisik | `http://<IP-komputer>:8000` |

Lalu jalankan:
```bash
flutter run
```

---

## Endpoint API Utama

| Method | Endpoint | Fungsi |
|---|---|---|
| POST | `/reports/` | Buat laporan baru (hilang/temuan), otomatis cek kemungkinan match |
| GET | `/reports/search?query=...` | Pencarian fuzzy berdasarkan kata kunci |
| GET | `/reports/{id}` | Ambil detail satu laporan |

---

## Justifikasi Teknis: MongoDB + Elasticsearch

| Kebutuhan | Kenapa Cocok |
|---|---|
| Struktur laporan fleksibel (jumlah foto beda-beda, atribut kategori barang bervariasi, gaya bahasa deskripsi bebas per user) | MongoDB tidak memaksa schema kaku seperti database relasional |
| Pencarian "dompet coklat" harus bisa menemukan "dompet warna cokelat kulit" | Elasticsearch punya fuzzy matching yang tidak bisa dilakukan efisien dengan query `LIKE` di SQL biasa |
| Auto-matching antara laporan hilang & temuan | Elasticsearch bisa scoring relevansi (deskripsi + kategori + lokasi) untuk menentukan seberapa mirip dua laporan |

---

## Rencana Pengembangan Selanjutnya

- [ ] Autentikasi user (saat ini `user_id` masih hardcode)
- [ ] Upload & tampilkan foto laporan
- [ ] Notifikasi push/WhatsApp otomatis saat ada match
- [ ] Kalibrasi ulang threshold skor auto-matching berdasarkan data asli
- [ ] Halaman riwayat laporan milik user
