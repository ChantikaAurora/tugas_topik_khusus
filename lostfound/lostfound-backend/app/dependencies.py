from bson import ObjectId
from bson.errors import InvalidId
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.auth_utils import decode_access_token
from app.database import users_collection

bearer_scheme = HTTPBearer()


async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)) -> dict:
    """Dependency yang dipasang di endpoint yang butuh login (mis. buat laporan).
    Membaca token dari header 'Authorization: Bearer <token>'."""
    token = credentials.credentials
    payload = decode_access_token(token)

    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token tidak valid atau sudah kedaluwarsa. Silakan login kembali.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if payload is None or "sub" not in payload:
        raise unauthorized

    try:
        user = await users_collection.find_one({"_id": ObjectId(payload["sub"])})
    except InvalidId:
        raise unauthorized

    if user is None:
        raise unauthorized

    user["_id"] = str(user["_id"])
    return user
