import os
from motor.motor_asyncio import AsyncIOMotorClient

# Saat dijalankan via Docker Compose, MONGO_URI di-override lewat environment variable
# menjadi "mongodb://mongodb:27017" (nama service di docker-compose.yml).
# Fallback ke localhost untuk development langsung di mesin lokal (tanpa Docker).
MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")
DB_NAME = "lostfound"

client = AsyncIOMotorClient(MONGO_URI)
db = client[DB_NAME]

reports_collection = db["reports"]
users_collection = db["users"]
