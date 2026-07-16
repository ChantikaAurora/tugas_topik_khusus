## 4. Skema SQL (DDL)  

-- tabel alamat
CREATE TABLE alamat (
    id_alamat INT AUTO_INCREMENT PRIMARY KEY,
    jalan VARCHAR(255) NOT NULL,
    kota VARCHAR(100) NOT NULL,
    provinsi VARCHAR(100),
    kode_pos VARCHAR(10),
    negara VARCHAR(50),
    INDEX (kota),
    INDEX (negara)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel pelanggan
CREATE TABLE pelanggan (
    id_pelanggan INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(150) NOT NULL,
    telepon VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    id_alamat INT,
    tanggal_daftar DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (id_alamat) REFERENCES alamat(id_alamat)
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX (nama),
    INDEX (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel barber_staff
CREATE TABLE barber_staff (
    id_staff INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(150) NOT NULL,
    telepon VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    tanggal_masuk DATE,
    id_role INT,
    FOREIGN KEY (id_role) REFERENCES role_staff(id_role)
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX (nama)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel role_staff
CREATE TABLE role_staff (
    id_role INT AUTO_INCREMENT PRIMARY KEY,
    nama_role VARCHAR(50) NOT NULL UNIQUE,
    deskripsi TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel layanan_jasa
CREATE TABLE layanan_jasa (
    id_layanan INT AUTO_INCREMENT PRIMARY KEY,
    nama_layanan VARCHAR(150) NOT NULL,
    deskripsi TEXT,
    harga DECIMAL(10,2) NOT NULL,
    durasi_menit INT,
    status INT DEFAULT 1,
    INDEX (nama_layanan)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel produk_jasa (untuk menggabungkan item fisik dan jasa)
CREATE TABLE produk_jasa (
    id_prod INT AUTO_INCREMENT PRIMARY KEY,
    tipe ENUM('produk','jasa') NOT NULL,
    referensi_id INT NOT NULL,
    INDEX (tipe)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel inventory_produk
CREATE TABLE inventory_produk (
    id_produk INT AUTO_INCREMENT PRIMARY KEY,
    nama_produk VARCHAR(150) NOT NULL,
    id_kategori INT,
    id_supplier INT,
    stok INT DEFAULT 0,
    harga_beli DECIMAL(10,2),
    harga_jual DECIMAL(10,2),
    INDEX (nama_produk),
    FOREIGN KEY (id_kategori) REFERENCES kategori_produk(id_kategori)
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id_supplier) REFERENCES supplier_produk(id_supplier)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel kategori_produk
CREATE TABLE kategori_produk (
    id_kategori INT AUTO_INCREMENT PRIMARY KEY,
    nama_kategori VARCHAR(100) NOT NULL,
    deskripsi TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel supplier_produk
CREATE TABLE supplier_produk (
    id_supplier INT AUTO_INCREMENT PRIMARY KEY,
    nama_supplier VARCHAR(150) NOT NULL,
    telepon VARCHAR(20),
    email VARCHAR(100),
    id_alamat INT,
    FOREIGN KEY (id_alamat) REFERENCES alamat(id_alamat)
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX (nama_supplier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel toko_cabang
CREATE TABLE toko_cabang (
    id_cabang INT AUTO_INCREMENT PRIMARY KEY,
    nama_cabang VARCHAR(150) NOT NULL,
    id_alamat INT,
    telepon VARCHAR(20),
    INDEX (nama_cabang),
    FOREIGN KEY (id_alamat) REFERENCES alamat(id_alamat)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel layanan_antar
CREATE TABLE layanan_antar (
    id_antar INT AUTO_INCREMENT PRIMARY KEY,
    nama_layanan VARCHAR(100) NOT NULL,
    tarif DECIMAL(10,2) NOT NULL,
    INDEX (nama_layanan)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel metode_pembayaran
CREATE TABLE metode_pembayaran (
    id_metode INT AUTO_INCREMENT PRIMARY KEY,
    nama_metode VARCHAR(100) NOT NULL UNIQUE,
    deskripsi TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel promo_diskon
CREATE TABLE promo_diskon (
    id_promo INT AUTO_INCREMENT PRIMARY KEY,
    kode VARCHAR(50) NOT NULL UNIQUE,
    persentase DECIMAL(5,2),
    tanggal_mulai DATE,
    tanggal_akhir DATE,
    status ENUM('aktif','nonaktif') DEFAULT 'aktif',
    INDEX (kode)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel reservasi_jadwal
CREATE TABLE reservasi_jadwal (
    id_reservasi INT AUTO_INCREMENT PRIMARY KEY,
    id_pelanggan INT NOT NULL,
    id_staff INT,
    id_layanan INT NOT NULL,
    id_cabang INT,
    tanggal_waktu DATETIME NOT NULL,
    id_status INT DEFAULT 1,
    id_promo INT,
    FOREIGN KEY (id_pelanggan) REFERENCES pelanggan(id_pelanggan)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_staff) REFERENCES barber_staff(id_staff)
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id_layanan) REFERENCES layanan_jasa(id_layanan)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_cabang) REFERENCES toko_cabang(id_cabang)
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id_status) REFERENCES status_layanan(id_status)
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id_promo) REFERENCES promo_diskon(id_promo)
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX (tanggal_waktu),
    INDEX (id_pelanggan),
    INDEX (id_staff)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel status_layanan
CREATE TABLE status_layanan (
    id_status INT AUTO_INCREMENT PRIMARY KEY,
    nama_status VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel transaksi_pembayaran
CREATE TABLE transaksi_pembayaran (
    id_transaksi INT AUTO_INCREMENT PRIMARY KEY,
    id_reservasi INT NOT NULL,
    id_metode INT,
    total DECIMAL(10,2) NOT NULL,
    tanggal_transaksi DATETIME DEFAULT CURRENT_TIMESTAMP,
    id_antar INT,
    FOREIGN KEY (id_reservasi) REFERENCES reservasi_jadwal(id_reservasi)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_metode) REFERENCES metode_pembayaran(id_metode)
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id_antar) REFERENCES layanan_antar(id_antar)
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX (tanggal_transaksi),
    INDEX (id_reservasi)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel detail_transaksi
CREATE TABLE detail_transaksi (
    id_detail INT AUTO_INCREMENT PRIMARY KEY,
    id_transaksi INT NOT NULL,
    id_produk INT,
    id_layanan INT,
    jumlah INT DEFAULT 1,
    harga_satuan DECIMAL(10,2),
    FOREIGN KEY (id_transaksi) REFERENCES transaksi_pembayaran(id_transaksi)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_produk) REFERENCES inventory_produk(id_produk)
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (id_layanan) REFERENCES layanan_jasa(id_layanan)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel penilaian_pelanggan
CREATE TABLE penilaian_pelanggan (
    id_penilaian INT AUTO_INCREMENT PRIMARY KEY,
    id_pelanggan INT NOT NULL,
    id_staff INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    komentar TEXT,
    tanggal DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pelanggan) REFERENCES pelanggan(id_pelanggan)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_staff) REFERENCES barber_staff(id_staff)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel shift_staff
CREATE TABLE shift_staff (
    id_shift INT AUTO_INCREMENT PRIMARY KEY,
    nama_shift VARCHAR(50) NOT NULL,
    jam_mulai TIME,
    jam_selesai TIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- tabel jadwal_kerja
CREATE TABLE jadwal_kerja (
    id_jadwal INT AUTO_INCREMENT PRIMARY KEY,
    id_staff INT NOT NULL,
    id_shift INT NOT NULL,
    tanggal DATE NOT NULL,
    id_cabang INT,
    FOREIGN KEY (id_staff) REFERENCES barber_staff(id_staff)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_shift) REFERENCES shift_staff(id_shift)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_cabang) REFERENCES toko_cabang(id_cabang)
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX (tanggal),
    INDEX (id_staff)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
