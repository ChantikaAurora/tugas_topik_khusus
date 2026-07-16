from pydantic import BaseModel, Field
from typing import Optional, Literal
from datetime import datetime


class ReportCreate(BaseModel):
    title: str
    description: str
    category: str
    location: str
    report_type: Literal["hilang", "temuan"]
    photo_url: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class ReportOut(ReportCreate):
    id: str = Field(alias="_id")
    user_id: str
    status: Literal["open", "matched"] = "open"
    created_at: datetime

    class Config:
        populate_by_name = True


class ReportStatusUpdate(BaseModel):
    status: Literal["open", "matched"]
