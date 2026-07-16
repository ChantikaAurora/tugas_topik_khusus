from fastapi import APIRouter, HTTPException, Depends, status
from bson import ObjectId

from app.database import users_collection
from app.models.user import UserRegister, UserLogin, UserOut, DeviceTokenUpdate
from app.auth_utils import hash_password, verify_password, create_access_token
from app.dependencies import get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])


def _user_out(user: dict) -> dict:
    return {"id": str(user["_id"]), "username": user["username"], "email": user["email"]}


@router.post("/register")
async def register(payload: UserRegister):
    existing = await users_collection.find_one({"email": payload.email})
    if existing:
        raise HTTPException(status_code=400, detail="Email sudah terdaftar")

    user_doc = {
        "username": payload.username,
        "email": payload.email,
        "hashed_password": hash_password(payload.password),
    }
    result = await users_collection.insert_one(user_doc)
    user_doc["_id"] = result.inserted_id

    # Auto-login setelah register: langsung buatkan access token
    access_token = create_access_token({"sub": str(result.inserted_id)})

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": _user_out(user_doc),
    }


@router.post("/login")
async def login(payload: UserLogin):
    user = await users_collection.find_one({"email": payload.email})
    invalid_credentials = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Email atau password salah",
    )

    if not user or not verify_password(payload.password, user["hashed_password"]):
        raise invalid_credentials

    access_token = create_access_token({"sub": str(user["_id"])})
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": _user_out(user),
    }


@router.get("/me", response_model=UserOut)
async def me(current_user: dict = Depends(get_current_user)):
    return _user_out(current_user)


@router.post("/device-token")
async def register_device_token(payload: DeviceTokenUpdate, current_user: dict = Depends(get_current_user)):
    """Dipanggil Flutter setelah login & setelah dapat FCM token dari Firebase,
    supaya backend tahu ke device mana push notification harus dikirim."""
    await users_collection.update_one(
        {"_id": ObjectId(current_user["_id"])},
        {"$set": {"device_token": payload.device_token}},
    )
    return {"message": "Device token berhasil disimpan"}
