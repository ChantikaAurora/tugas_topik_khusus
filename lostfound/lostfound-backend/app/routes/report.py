import json
from fastapi import APIRouter, HTTPException, Depends
from datetime import datetime, timezone
from bson import ObjectId
from bson.errors import InvalidId

from app.database import reports_collection
from app.es_client import search_reports, index_report
from app.queue_client import publish_event, redis_client, STREAM_REPORT_CREATED
from app.models.report import ReportCreate, ReportStatusUpdate
from app.dependencies import get_current_user

router = APIRouter(prefix="/reports", tags=["reports"])

SEARCH_CACHE_TTL_SECONDS = 30  # cache pendek karena data laporan sering berubah


@router.post("/")
async def create_report(payload: ReportCreate, current_user: dict = Depends(get_current_user)):
    report_doc = payload.model_dump()
    report_doc["user_id"] = current_user["_id"]  # diambil dari token, bukan dari input client
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
async def search(
    query: str,
    report_type: str = None,
    lat: float = None,
    lon: float = None,
    radius_km: float = None,
):
    cache_key = f"search:{query}:{report_type or 'all'}:{lat}:{lon}:{radius_km}"

    # 1. Cek cache dulu
    cached = await redis_client.get(cache_key)
    if cached:
        return {"results": json.loads(cached), "from_cache": True}

    # 2. Kalau tidak ada di cache, query ke Elasticsearch
    results = await search_reports(query, report_type, lat=lat, lon=lon, radius_km=radius_km)

    # 3. Simpan hasil ke cache untuk request berikutnya
    await redis_client.set(cache_key, json.dumps(results), ex=SEARCH_CACHE_TTL_SECONDS)

    return {"results": results, "from_cache": False}


@router.get("/mine")
async def get_my_reports(current_user: dict = Depends(get_current_user)):
    """Riwayat laporan milik user yang sedang login, terbaru duluan."""
    cursor = reports_collection.find({"user_id": current_user["_id"]}).sort("created_at", -1)
    reports = []
    async for report in cursor:
        report["_id"] = str(report["_id"])
        reports.append(report)
    return {"results": reports}


@router.patch("/{report_id}/status")
async def update_report_status(
    report_id: str,
    payload: ReportStatusUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Tandai laporan sebagai 'matched' (sudah ketemu) atau kembalikan ke 'open'.
    Hanya pemilik laporan yang boleh mengubah statusnya."""
    try:
        obj_id = ObjectId(report_id)
    except InvalidId:
        raise HTTPException(status_code=400, detail="ID laporan tidak valid")

    report = await reports_collection.find_one({"_id": obj_id})
    if not report:
        raise HTTPException(status_code=404, detail="Laporan tidak ditemukan")
    if report["user_id"] != current_user["_id"]:
        raise HTTPException(status_code=403, detail="Kamu tidak berhak mengubah laporan ini")

    await reports_collection.update_one({"_id": obj_id}, {"$set": {"status": payload.status}})

    # Sinkronkan juga ke Elasticsearch supaya hasil pencarian ikut ter-update
    report["status"] = payload.status
    report["_id"] = str(report["_id"])
    report_for_index = {k: v for k, v in report.items() if k != "_id"}
    if isinstance(report_for_index.get("created_at"), datetime):
        report_for_index["created_at"] = report_for_index["created_at"].isoformat()
    await index_report(report_id, report_for_index)

    return {"message": "Status laporan berhasil diperbarui", "status": payload.status}


@router.get("/{report_id}")
async def get_report(report_id: str):
    report = await reports_collection.find_one({"_id": ObjectId(report_id)})
    if not report:
        raise HTTPException(status_code=404, detail="Laporan tidak ditemukan")
    report["_id"] = str(report["_id"])
    return report
