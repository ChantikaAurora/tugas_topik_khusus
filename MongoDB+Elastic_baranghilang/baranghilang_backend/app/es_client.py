from elasticsearch import AsyncElasticsearch

ES_URL = "http://localhost:9200"
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
        }
    }
}


async def ensure_index_exists():
    exists = await es.indices.exists(index=INDEX_NAME)
    if not exists:
        await es.indices.create(index=INDEX_NAME, body=INDEX_MAPPING)


async def index_report(report_id: str, report: dict):
    await es.index(index=INDEX_NAME, id=report_id, document=report)


async def search_reports(query: str, report_type: str = None):
    """Fuzzy search berdasarkan title, description, location"""
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

    result = await es.search(
        index=INDEX_NAME,
        query={"bool": {"must": must_clauses}},
        size=20,
    )
    return [hit["_source"] | {"_id": hit["_id"], "_score": hit["_score"]} for hit in result["hits"]["hits"]]


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
