"""
Notification Service (Worker)
-----------------------------
Proses terpisah yang mengonsumsi event `match_found` dan mengirim push
notification (Firebase Cloud Messaging) ke kedua user yang laporannya cocok.

Jalankan terpisah:
    python3.10 notification_worker.py
"""

import asyncio
from bson import ObjectId
from bson.errors import InvalidId

from app.queue_client import consume_events, ack_event, STREAM_MATCH_FOUND
from app.database import users_collection
from app.firebase_client import send_push_notification


async def send_notification(user_id: str, title: str, body: str):
    try:
        user = await users_collection.find_one({"_id": ObjectId(user_id)})
    except InvalidId:
        print(f"[Notification Service] user_id tidak valid: {user_id}")
        return

    if not user:
        print(f"[Notification Service] User {user_id} tidak ditemukan, notifikasi dilewati")
        return

    device_token = user.get("device_token")
    if not device_token:
        # User belum pernah login di HP / belum kasih izin notifikasi
        print(f"[Notification Service] User {user_id} belum punya device_token, notifikasi dilewati")
        return

    sent = send_push_notification(device_token, title, body)
    status_text = "berhasil dikirim" if sent else "gagal dikirim"
    print(f"[Notification Service] Push ke user '{user_id}' {status_text}: {body}")


async def process_match_found(payload: dict):
    score = payload["score"]
    title = "Kemungkinan Barangmu Ditemukan!"
    body = f"Ada laporan lain yang mirip dengan laporanmu (skor kecocokan: {score:.2f})"

    await send_notification(payload["report_user_id"], title, body)
    await send_notification(payload["matched_user_id"], title, body)


async def main():
    print("[Notification Service] Worker mulai berjalan, menunggu event match_found...")

    async for message_id, payload in consume_events(STREAM_MATCH_FOUND, consumer_name="notification-worker-1"):
        try:
            await process_match_found(payload)
        except Exception as e:
            print(f"[Notification Service] Error memproses event {message_id}: {e}")
        finally:
            await ack_event(STREAM_MATCH_FOUND, message_id)


if __name__ == "__main__":
    asyncio.run(main())
