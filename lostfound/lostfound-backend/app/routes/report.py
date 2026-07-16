import json
from fastapi import APIRouter, HTTPException
from datetime import datetime, timezone
from bson import ObjectId

from app.database import reports_collection
from app.es_client import search_reports
from app.queue_client import publish_event, redis_client, STREAM_REPORT_CREATED
from app.models.report import ReportCreate

router = APIRouter(prefix="/reports", tags=["reports"])

SEARCH_CACHE_TTL_SECONDS = 30  # cache pendek karena data laporan sering berubah


@router.post("/")
async def create_report(payload: ReportCreate):
    report_doc = payload.model_dump()
    report_doc["status"] = "open"
    report_doc["created_at"] = datetime.now(timezone.utc)

    # 1. Simpan ke MongoDB (source of truth)
    result = await reports_collection.insert_one(report_doc)
    report_id = str(result.inserted_id)

    # 2. Publish event ke Message Queue -- TIDAK menunggu proses index/matching selesai
    # (anti-timeout, sesuai pola event-driven di dokumen arsitektur)
    event_payload = {
        **{k: v for k, v in report_doc.items() if k not in ("created_at", "_id")},
        "id": report_id,
        "created_at": report_doc["created_at"].isoformat(),
    }
    await publish_event(STREAM_REPORT_CREATED, event_payload)

    # 3. Langsung kembalikan respons sukses ke user.
    # Auto-matching diproses di background oleh Search & Matching Service (worker.py)
    # dan notifikasi akan dikirim terpisah oleh Notification Service.
    return {
        "id": report_id,
        "message": "Laporan berhasil dibuat, sedang diproses untuk pencocokan otomatis",
    }


@router.get("/search")
async def search(query: str, report_type: str = None):
    cache_key = f"search:{query}:{report_type or 'all'}"

    # 1. Cek cache dulu
    cached = await redis_client.get(cache_key)
    if cached:
        return {"results": json.loads(cached), "from_cache": True}

    # 2. Kalau tidak ada di cache, query ke Elasticsearch
    results = await search_reports(query, report_type)

    # 3. Simpan hasil ke cache untuk request berikutnya
    await redis_client.set(cache_key, json.dumps(results), ex=SEARCH_CACHE_TTL_SECONDS)

    return {"results": results, "from_cache": False}


@router.get("/{report_id}")
async def get_report(report_id: str):
    report = await reports_collection.find_one({"_id": ObjectId(report_id)})
    if not report:
        raise HTTPException(status_code=404, detail="Laporan tidak ditemukan")
    report["_id"] = str(report["_id"])
    return report
