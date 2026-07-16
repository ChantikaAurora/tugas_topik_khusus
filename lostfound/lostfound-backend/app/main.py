import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager

from app.es_client import ensure_index_exists
from app.database import users_collection
from app.routes import report, upload, auth


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Dijalankan sekali saat aplikasi start: pastikan index Elasticsearch sudah ada
    await ensure_index_exists()
    # Pastikan email user unik di level database (lapisan pertahanan kedua selain cek manual di route)
    await users_collection.create_index("email", unique=True)
    yield


app = FastAPI(title="Lost & Found API", lifespan=lifespan)

os.makedirs("app/static/uploads", exist_ok=True)
app.mount("/static", StaticFiles(directory="app/static"), name="static")

app.include_router(report.router)
app.include_router(upload.router)
app.include_router(auth.router)


@app.get("/")
async def root():
    return {"message": "Lost & Found API is running"}
