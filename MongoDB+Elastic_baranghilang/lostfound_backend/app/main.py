from fastapi import FastAPI
from contextlib import asynccontextmanager
import uvicorn
from app.es_client import ensure_index_exists
from app.routes import report


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Dijalankan sekali saat aplikasi start: pastikan index Elasticsearch sudah ada
    await ensure_index_exists()
    yield


app = FastAPI(title="Lost & Found API", lifespan=lifespan)

app.include_router(report.router)


@app.get("/")
async def root():
    return {"message": "Lost & Found API is running"}


