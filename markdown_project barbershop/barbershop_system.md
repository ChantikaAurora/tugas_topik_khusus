# Sistem Informasi Barbershop  
## 1. Deskripsi Sistem  
Sistem ini dirancang untuk mengelola seluruh operasional barbershop modern:  
- manajemen pelanggan dan staff barber  
- pemesanan layanan dan penjadwalan  
- persediaan produk (produk perawatan, alat, dsb.)  
- penanganan pembayaran dan promosi  
- pelacakan status layanan dan penilaian  
Struktur mengikuti kompleksitas basis data universitas, dengan 15–20 tabel yang saling berrelasi.

## 2. Daftar Tabel  
1. **pelanggan**  
2. **barber_staff**  
3. **layanan_jasa**  
4. **reservasi_jadwal**  
5. **transaksi_pembayaran**  
6. **inventory_produk**  
7. **status_layanan**  
8. **supplier_produk**  
9. **kategori_produk**  
10. **toko_cabang**  
11. **promo_diskon**  
12. **alamat**  
13. **metode_pembayaran**  
14. **penilaian_pelanggan**  
15. **produk_jasa**  
16. **detail_transaksi**  
17. **shift_staff**  
18. **role_staff**  
19. **jadwal_kerja**  
20. **layanan_antar**  

## 3. Mapping Relasi Northwind → Barbershop  

| Northwind           | Barbershop         |
|---------------------|--------------------|
| customers           | pelanggan          |
| employees           | barber_staff       |
| shippers            | layanan_antar      |
| orders              | reservasi_jadwal   |
| order_details       | detail_transaksi   |
| products            | inventory_produk   |
| categories          | kategori_produk    |
| suppliers           | supplier_produk    |
| territories         | toko_cabang        |
| regions             | alamat             |
| products_suppliers  | supplier_produk    |
| invoices            | transaksi_pembayaran |
| payments            | metode_pembayaran  |
| employee_territories| jadwal_kerja       |
| roles               | role_staff         |
