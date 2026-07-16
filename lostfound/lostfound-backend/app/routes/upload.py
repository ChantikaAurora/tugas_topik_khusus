import os
import uuid
from fastapi import APIRouter, UploadFile, File, HTTPException

router = APIRouter(prefix="/upload", tags=["upload"])

# Folder tempat foto disimpan. Di-mount sebagai static file di main.py
# supaya bisa diakses lewat URL (misal http://localhost:8000/static/xxx.jpg)
UPLOAD_DIR = "app/static/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB


@router.post("/photo")
async def upload_photo(file: UploadFile = File(...)):
    ext = os.path.splitext(file.filename or "")[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Format file tidak didukung. Gunakan: {', '.join(ALLOWED_EXTENSIONS)}",
        )

    contents = await file.read()
    if len(contents) > MAX_FILE_SIZE_BYTES:
        raise HTTPException(status_code=400, detail="Ukuran file maksimal 5MB")

    # Nama file unik supaya tidak bentrok antar user
    filename = f"{uuid.uuid4().hex}{ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    with open(filepath, "wb") as f:
        f.write(contents)

    # URL ini yang disimpan di field photo_url pada laporan
    photo_url = f"/static/uploads/{filename}"
    return {"photo_url": photo_url}
