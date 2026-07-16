"""
Search & Matching Service (Worker)
----------------------------------
Proses terpisah yang berjalan sendiri (bukan bagian dari FastAPI app).
Tugasnya:
1. Mengonsumsi event `report_created` dari Redis Stream
2. Meng-index laporan baru ke Elasticsearch
3. Menjalankan fuzzy matching untuk mencari laporan lawan jenis yang mirip
4. Kalau ada match, publish event `match_found` ke queue untuk Notification Service

Jalankan terpisah dari API utama:
    python3.10 worker.py
"""

import asyncio

from app.es_client import ensure_index_exists, index_report, find_matching_reports
from app.queue_client import (
    consume_events,
    ack_event,
    publish_event,
    STREAM_REPORT_CREATED,
    STREAM_MATCH_FOUND,
)


async def process_report_created(payload: dict):
    report_id = payload["id"]
    print(f"[Search Service] Memproses laporan baru: {report_id} ({payload['report_type']})")

    # 1. Index ke Elasticsearch
    await index_report(report_id, payload)
    print(f"[Search Service] Berhasil di-index ke Elasticsearch: {report_id}")

    # 2. Cari kemungkinan match dengan laporan lawan jenis
    matches = await find_matching_reports(payload)

    if matches:
        print(f"[Search Service] Ditemukan {len(matches)} kemungkinan match untuk {report_id}")
        for match in matches:
            match_event = {
                "report_id": report_id,
                "report_user_id": payload["user_id"],
                "matched_report_id": match["_id"],
                "matched_user_id": match["_source"]["user_id"],
                "score": match["_score"],
            }
            await publish_event(STREAM_MATCH_FOUND, match_event)
    else:
        print(f"[Search Service] Tidak ada match untuk {report_id}")


async def main():
    await ensure_index_exists()
    print("[Search Service] Worker mulai berjalan, menunggu event...")

    async for message_id, payload in consume_events(STREAM_REPORT_CREATED, consumer_name="search-worker-1"):
        try:
            await process_report_created(payload)
        except Exception as e:
            print(f"[Search Service] Error memproses event {message_id}: {e}")
        finally:
            # ACK tetap dipanggil walau error, supaya event tidak diproses ulang selamanya.
            # Untuk production, sebaiknya event yang gagal terus-menerus dikirim ke dead-letter queue.
            await ack_event(STREAM_REPORT_CREATED, message_id)


if __name__ == "__main__":
    asyncio.run(main())
