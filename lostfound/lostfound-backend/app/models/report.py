from pydantic import BaseModel, Field
from typing import Optional, Literal
from datetime import datetime


class ReportCreate(BaseModel):
    title: str
    description: str
    category: str
    location: str
    report_type: Literal["hilang", "temuan"]
    user_id: str
    photo_url: Optional[str] = None


class ReportOut(ReportCreate):
    id: str = Field(alias="_id")
    status: Literal["open", "matched"] = "open"
    created_at: datetime

    class Config:
        populate_by_name = True
