import os
from elasticsearch import AsyncElasticsearch

# Di Docker Compose di-override jadi "http://elasticsearch:9200" (nama service).
ES_URL = os.getenv("ES_URL", "http://localhost:9200")
INDEX_NAME = "reports"

es = AsyncElasticsearch(ES_URL)

# Mapping index: menentukan field mana yang bisa di-fuzzy search
INDEX_MAPPING = {
    "mappings": {
        "properties": {
            "title": {"type": "text"},
            "description": {"type": "text"},
            "category": {"type": "keyword"},
            "location": {"type": "text"},
            "report_type": {"type": "keyword"},  # "hilang" atau "temuan"
            "status": {"type": "keyword"},        # "open" atau "matched"
            "created_at": {"type": "date"},
            "user_id": {"type": "keyword"},
            "photo_url": {"type": "keyword"},     # tidak perlu full-text search, cuma disimpan & ditampilkan
            "coordinates": {"type": "geo_point"},  # {"lat": ..., "lon": ...}, dipakai untuk filter jarak
        }
    }
}


async def ensure_index_exists():
    exists = await es.indices.exists(index=INDEX_NAME)
    if not exists:
        await es.indices.create(index=INDEX_NAME, body=INDEX_MAPPING)


async def index_report(report_id: str, report: dict):
    """Index satu laporan ke Elasticsearch. Kalau ada latitude & longitude,
    otomatis dibentuk jadi field geo_point 'coordinates' untuk filter jarak."""
    doc = dict(report)
    lat = doc.get("latitude")
    lon = doc.get("longitude")
    if lat is not None and lon is not None:
        doc["coordinates"] = {"lat": lat, "lon": lon}

    await es.index(index=INDEX_NAME, id=report_id, document=doc)


async def search_reports(
    query: str,
    report_type: str = None,
    lat: float = None,
    lon: float = None,
    radius_km: float = None,
):
    """Fuzzy search berdasarkan title, description, location.
    Kalau lat/lon/radius_km diisi, hasil difilter berdasarkan jarak dan
    diurutkan dari yang paling dekat."""
    must_clauses = [
        {
            "multi_match": {
                "query": query,
                "fields": ["title", "description", "location"],
                "fuzziness": "AUTO",
            }
        }
    ]
    if report_type:
        must_clauses.append({"term": {"report_type": report_type}})

    filter_clauses = []
    sort_clauses = ["_score"]
    if lat is not None and lon is not None and radius_km is not None:
        filter_clauses.append(
            {
                "geo_distance": {
                    "distance": f"{radius_km}km",
                    "coordinates": {"lat": lat, "lon": lon},
                }
            }
        )
        sort_clauses = [
            {
                "_geo_distance": {
                    "coordinates": {"lat": lat, "lon": lon},
                    "order": "asc",
                    "unit": "km",
                }
            },
            "_score",
        ]

    result = await es.search(
        index=INDEX_NAME,
        query={"bool": {"must": must_clauses, "filter": filter_clauses}},
        sort=sort_clauses,
        size=20,
    )
    hits = []
    for hit in result["hits"]["hits"]:
        item = hit["_source"] | {"_id": hit["_id"], "_score": hit["_score"]}
        # sort key kedua (kalau ada geo sort) berisi jarak dalam km
        if lat is not None and lon is not None and radius_km is not None and hit.get("sort"):
            item["distance_km"] = round(hit["sort"][0], 2)
        hits.append(item)
    return hits


async def find_matching_reports(report: dict):
    """Cari laporan lawan jenis (hilang<->temuan) yang mirip"""
    opposite_type = "temuan" if report["report_type"] == "hilang" else "hilang"

    result = await es.search(
        index=INDEX_NAME,
        query={
            "bool": {
                "must": [
                    {"term": {"report_type": opposite_type}},
                    {"term": {"status": "open"}},
                    {
                        "multi_match": {
                            "query": f"{report['title']} {report['description']} {report['location']}",
                            "fields": ["title", "description", "location"],
                            "fuzziness": "AUTO",
                        }
                    },
                ]
            }
        },
        size=5,
    )
    # threshold sederhana: skor Elasticsearch di atas 3 dianggap kandidat match kuat
    # (nilai ini perlu kamu kalibrasi lagi berdasarkan uji coba data asli)
    matches = [hit for hit in result["hits"]["hits"] if hit["_score"] >= 3]
    return matches
