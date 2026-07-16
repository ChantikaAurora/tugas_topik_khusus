import redis
import json

# Konfigurasi 

REDIS_HOST = "localhost"
REDIS_PORT = 6379

KEY_KATALOG    = "toko:katalog"
KEY_PESANAN    = "toko:pesanan"
KEY_VIP        = "toko:pelanggan_vip"
KEY_PENGUNJUNG = "toko:pengunjung"
KEY_FLASHSALE  = "toko:flashsale"

FLASHSALE_TTL = 15  # detik

#  Koneksi

def connect() -> redis.Redis:
    return redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)

# Fungsi Katalog 

def simpan_katalog(r: redis.Redis, produk: list[dict]) -> None:
    r.delete(KEY_KATALOG)
    for item in produk:
        r.hset(KEY_KATALOG, item["kode"], json.dumps(item))

def tampilkan_katalog(r: redis.Redis) -> None:
    katalog = r.hgetall(KEY_KATALOG)
    print("\n🌺 Katalog Bunga:")
    print(f"   {'No':<4} {'Nama':<22} {'Harga':<15} {'Stok'}")
    print(f"   {'─' * 48}")
    for i, (_, data) in enumerate(katalog.items(), 1):
        item = json.loads(data)
        print(f"   {i:<4} {item['nama']:<22} Rp {item['harga']:>7,}   {item['stok']} pcs")

# Fungsi Pesanan

def simpan_pesanan(r: redis.Redis, pesanan: list[str]) -> None:
    r.delete(KEY_PESANAN)
    for p in pesanan:
        r.rpush(KEY_PESANAN, p)

def tampilkan_pesanan(r: redis.Redis) -> None:
    riwayat = r.lrange(KEY_PESANAN, 0, -1)
    print("\n Riwayat Pesanan:")
    for i, pesanan in enumerate(riwayat, 1):
        print(f"   {i}. {pesanan}")

# Fungsi Pengunjung 

def tambah_pengunjung(r: redis.Redis, jumlah: int = 1) -> str:
    for _ in range(jumlah):
        r.incr(KEY_PENGUNJUNG)
    return r.get(KEY_PENGUNJUNG)

# Fungsi Flash Sale

def aktifkan_flashsale(r: redis.Redis, pesan: str) -> None:
    r.setex(KEY_FLASHSALE, FLASHSALE_TTL, pesan)

def tampilkan_flashsale(r: redis.Redis) -> None:
    pesan = r.get(KEY_FLASHSALE)
    sisa  = r.ttl(KEY_FLASHSALE)
    print(f"\n Flash Sale  : {pesan}")
    print(f"   Berakhir   : {sisa} detik lagi")

# Fungsi Pelanggan VIP

def simpan_vip(r: redis.Redis, nama_list: list[str]) -> None:
    r.delete(KEY_VIP)
    for nama in nama_list:
        r.sadd(KEY_VIP, nama)

def tampilkan_vip(r: redis.Redis) -> None:
    daftar = sorted(r.smembers(KEY_VIP))
    print(f"\n Pelanggan VIP ({len(daftar)} orang):")
    for nama in daftar:
        print(f"   ✦ {nama}")

# Cleanup 

def cleanup(r: redis.Redis) -> None:
    r.delete(KEY_KATALOG, KEY_PESANAN, KEY_VIP, KEY_PENGUNJUNG, KEY_FLASHSALE)

#  Main 

def main():
    r = connect()

    print("=" * 50)
    print("   🌸  AURORA FLOWER SHOP  🌸")
    print("=" * 50)

    # Data
    produk = [
        {"kode": "MWR", "nama": "Mawar Merah",    "harga": 25000, "stok": 10},
        {"kode": "TLP", "nama": "Tulip Pink",     "harga": 35000, "stok": 7},
        {"kode": "SNF", "nama": "Bunga Matahari", "harga": 20000, "stok": 15},
        {"kode": "LVN", "nama": "Lavender",       "harga": 30000, "stok": 5},
    ]
    pesanan = [
        "Tulip Pink x2       - Rp 70.000",
        "Mawar Merah x1      - Rp 25.000",
        "Lavender x3         - Rp 90.000",
    ]
    vip = ["Aurora", "Dewi", "Rina", "Siti"]

    # Jalankan semua fitur
    simpan_katalog(r, produk)
    tampilkan_katalog(r)

    total = tambah_pengunjung(r, jumlah=3)
    print(f"\n Pengunjung hari ini : {total} orang")

    simpan_pesanan(r, pesanan)
    tampilkan_pesanan(r)

    aktifkan_flashsale(r, "DISKON 20% Mawar Merah!")
    tampilkan_flashsale(r)

    simpan_vip(r, vip)
    tampilkan_vip(r)

    cleanup(r)
    print("\n  Data sementara berhasil dihapus.")
    print("\n" + "=" * 50)
    print("   Program selesai. Sampai jumpa! 🌸")
    print("=" * 50)


if __name__ == "__main__":
    main()