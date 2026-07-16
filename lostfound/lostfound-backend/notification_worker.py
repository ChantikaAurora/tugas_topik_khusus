"""
Notification Service (Worker)
-----------------------------
Proses terpisah yang mengonsumsi event `match_found` dan mengirim notifikasi
ke kedua user yang laporannya cocok.

Untuk sekarang, "pengiriman notifikasi" masih berupa print ke console (stub).
Nanti tinggal ganti fungsi send_notification() dengan integrasi WhatsApp Business
API atau push notification (Firebase Cloud Messaging) sesuai rencana di dokumen.

Jalankan terpisah:
    python3.10 notification_worker.py
"""

import asyncio

from app.queue_client import consume_events, ack_event, STREAM_MATCH_FOUND


async def send_notification(user_id: str, message: str):
    # TODO: ganti dengan WhatsApp Business API / Firebase Cloud Messaging
    print(f"[Notification Service] -> Kirim ke user '{user_id}': {message}")


async def process_match_found(payload: dict):
    score = payload["score"]
    await send_notification(
        payload["report_user_id"],
        f"Laporanmu kemungkinan cocok dengan laporan lain (skor kecocokan: {score:.2f})",
    )
    await send_notification(
        payload["matched_user_id"],
        f"Laporanmu kemungkinan cocok dengan laporan lain (skor kecocokan: {score:.2f})",
    )


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
