from unittest import result

from fastapi import APIRouter, HTTPException
from datetime import datetime, timezone
from bson import ObjectId

from app.database import reports_collection
from app.es_client import index_report, search_reports, find_matching_reports
from app.models.report import ReportCreate

router = APIRouter(prefix="/reports", tags=["reports"])


@router.post("/")
async def create_report(payload: ReportCreate):
    report_doc = payload.model_dump()
    report_doc["status"] = "open"
    report_doc["created_at"] = datetime.now(timezone.utc)
    es_doc = {**report_doc, "created_at": report_doc["created_at"].isoformat()}


    # 1. Simpan ke MongoDB (source of truth)
    result = await reports_collection.insert_one(report_doc)
    report_id = str(result.inserted_id)

    # 2. Index ke Elasticsearch untuk keperluan search & matching
    await index_report(report_id, es_doc)

    # 3. Cek apakah ada laporan lawan jenis yang mirip
    matches = await find_matching_reports({**report_doc, "id": report_id})

    return {
        "id": report_id,
        "message": "Laporan berhasil dibuat",
        "potential_matches": [
            {"id": m["_id"], "score": m["_score"], **m["_source"]} for m in matches
        ],
    }


@router.get("/search")
async def search(query: str, report_type: str = None):
    results = await search_reports(query, report_type)
    return {"results": results}


@router.get("/{report_id}")
async def get_report(report_id: str):
    report = await reports_collection.find_one({"_id": ObjectId(report_id)})
    if not report:
        raise HTTPException(status_code=404, detail="Laporan tidak ditemukan")
    report["_id"] = str(report["_id"])
    return report
