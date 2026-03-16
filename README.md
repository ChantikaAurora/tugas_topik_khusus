# Aurora Flower Shop - Redis Demo

Program sederhana menggunakan **Redis** dan **Python** untuk mensimulasikan sistem toko bunga berbasis penyimpanan data in-memory.

---

##  Deskripsi

Program ini mensimulasikan sistem toko bunga yang memanfaatkan Redis sebagai penyimpanan data sementara. Program mendemonstrasikan berbagai perintah Redis seperti penyimpanan katalog produk, pencatatan pesanan, counter pengunjung, promo flash sale dengan waktu kedaluwarsa, dan manajemen pelanggan VIP.

---

##  Fitur

- Menyimpan dan menampilkan katalog produk bunga (Hash)
- Counter pengunjung toko otomatis (Increment)
- Mencatat riwayat pesanan (List)
- Flash sale dengan batas waktu kedaluwarsa / TTL (String + Expire)
- Mengelola daftar pelanggan VIP (Set)
- Menghapus data sementara setelah program selesai (Delete)

---

## Teknologi yang Digunakan

| Teknologi | Keterangan               |
|-----------|--------------------------|
| Python 3  | Bahasa pemrograman utama |
| Redis     | Database in-memory       |
| redis-py  | Library Python untuk Redis |

---

## Struktur Folder

```
tugas-redis/
├── venv/           # Virtual environment (tidak di-push ke GitHub)
├── redis_app.py    # File program utama
└── README.md       # Dokumentasi proyek
```

---

## Cara Menjalankan

**1. Install library Redis**
```bash
pip install redis
```

**2. Jalankan Redis server**
```bash
redis-server
```

**3. Aktifkan virtual environment (Mac/Linux)**
```bash
python3 -m venv venv
source venv/bin/activate
```

**4. Jalankan program**
```bash
python3 redis_app.py
```


---

## Perintah Redis yang Digunakan

| Perintah           | Fungsi dalam Program                        |
|--------------------|---------------------------------------------|
| `HSET` & `HGETALL` | Simpan & tampilkan katalog bunga            |
| `INCR`             | Hitung pengunjung toko secara otomatis      |
| `RPUSH` & `LRANGE` | Simpan & tampilkan riwayat pesanan          |
| `SETEX` & `TTL`    | Flash sale dengan waktu kedaluwarsa         |
| `SADD` & `SMEMBERS`| Kelola daftar pelanggan VIP (unik, no-duplikat) |
| `DEL`              | Hapus semua data sementara                  |

---

## Author

**Chantika Aurora Akmal**  
NIM: 2311083001  
Prodi: Teknik Rekayasa Perangkat Lunak  
Politeknik Negeri Padang
