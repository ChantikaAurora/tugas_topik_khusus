import json
import redis.asyncio as redis

REDIS_URL = "redis://localhost:6379"

STREAM_REPORT_CREATED = "report_created"
STREAM_MATCH_FOUND = "match_found"
CONSUMER_GROUP = "lostfound-workers"

redis_client = redis.from_url(REDIS_URL, decode_responses=True)


async def publish_event(stream: str, payload: dict):
    """Kirim event baru ke stream (dipanggil oleh producer, misal Report Service)"""
    await redis_client.xadd(stream, {"data": json.dumps(payload)})


async def ensure_consumer_group(stream: str, group: str = CONSUMER_GROUP):
    """Pastikan consumer group sudah ada sebelum worker mulai baca stream.
    Kalau stream belum ada, otomatis dibuat (mkstream=True)."""
    try:
        await redis_client.xgroup_create(stream, group, id="0", mkstream=True)
    except redis.ResponseError as e:
        if "BUSYGROUP" not in str(e):
            raise  # group sudah ada, aman diabaikan


async def consume_events(stream: str, consumer_name: str, group: str = CONSUMER_GROUP):
    """Generator async: terus-menerus ambil event baru dari stream (blocking read).
    Dipakai oleh worker (Search Service, Notification Service)."""
    await ensure_consumer_group(stream, group)
    while True:
        results = await redis_client.xreadgroup(
            group, consumer_name, {stream: ">"}, count=10, block=5000
        )
        if not results:
            continue
        for _stream_name, messages in results:
            for message_id, fields in messages:
                payload = json.loads(fields["data"])
                yield message_id, payload
                # ACK setelah selesai diproses (di-ack di worker, lihat catatan di bawah)


async def ack_event(stream: str, message_id: str, group: str = CONSUMER_GROUP):
    await redis_client.xack(stream, group, message_id)
