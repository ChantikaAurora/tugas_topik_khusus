"""
Firebase Cloud Messaging client
--------------------------------
Dipakai oleh Notification Service (notification_worker.py) untuk mengirim
push notification ke device user saat ada match ditemukan.

SETUP YANG PERLU KAMU LAKUKAN (tidak bisa dibuatkan otomatis, ini kredensial akun kamu):
1. Buat project di https://console.firebase.google.com
2. Buka Project Settings -> Service Accounts -> Generate new private key
   -> download file JSON-nya
3. Simpan file itu di lokasi aman, misal: lostfound-backend/firebase-service-account.json
   (JANGAN commit file ini ke Git -- sudah ditambahkan ke .gitignore)
4. Set environment variable FIREBASE_CREDENTIALS_PATH ke path file tersebut,
   atau taruh di docker-compose.yml sebagai environment variable + volume mount

Kalau env var belum di-set, worker akan tetap jalan tapi hanya nge-print
peringatan ke console (tidak crash) supaya development lain tidak terganggu.
"""

import os
import firebase_admin
from firebase_admin import credentials, messaging

FIREBASE_CREDENTIALS_PATH = os.getenv("FIREBASE_CREDENTIALS_PATH")

_firebase_app = None
_firebase_enabled = False

if FIREBASE_CREDENTIALS_PATH and os.path.exists(FIREBASE_CREDENTIALS_PATH):
    cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
    _firebase_app = firebase_admin.initialize_app(cred)
    _firebase_enabled = True
else:
    print(
        "[Firebase] PERINGATAN: FIREBASE_CREDENTIALS_PATH belum diset atau file tidak ditemukan. "
        "Push notification akan di-skip (hanya di-print ke console). "
        "Lihat komentar di app/firebase_client.py untuk cara setup."
    )


def send_push_notification(device_token: str, title: str, body: str) -> bool:
    """Kirim satu push notification ke satu device token. Return True kalau berhasil."""
    if not _firebase_enabled:
        print(f"[Firebase] (skip, belum dikonfigurasi) -> {title}: {body}")
        return False

    if not device_token:
        return False

    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        token=device_token,
    )
    try:
        messaging.send(message)
        return True
    except Exception as e:
        print(f"[Firebase] Gagal mengirim notifikasi: {e}")
        return False
