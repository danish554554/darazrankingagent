from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

# Rank Log Schemas
class SearchRankLogBase(BaseModel):
    page_number: Optional[int] = None
    absolute_position: Optional[int] = None
    organic_position: Optional[int] = None
    is_sponsored: bool = False
    price: Optional[float] = None
    rating: Optional[float] = None
    review_count: Optional[int] = None
    found: bool = False
    notes: Optional[str] = None

class SearchRankLogCreate(SearchRankLogBase):
    keyword_id: int

class SearchRankLogResponse(SearchRankLogBase):
    id: int
    keyword_id: int
    recorded_at: datetime

    class Config:
        from_attributes = True


# Keyword Schemas
class KeywordBase(BaseModel):
    keyword: str
    target_rank: int = 10
    check_frequency_hours: int = 12
    is_active: bool = True

class KeywordCreate(KeywordBase):
    product_id: int

class KeywordResponse(KeywordBase):
    id: int
    product_id: int
    created_at: datetime
    latest_rank: Optional[SearchRankLogResponse] = None

    class Config:
        from_attributes = True


# Product Schemas
class ProductBase(BaseModel):
    daraz_item_id: str
    sku: Optional[str] = None
    title: str
    product_url: str
    image_url: Optional[str] = None

class ProductCreate(ProductBase):
    pass

class ProductResponse(ProductBase):
    id: int
    created_at: datetime
    keywords: List[KeywordResponse] = []

    class Config:
        from_attributes = True


# Live Check & Prompt Schemas
class LiveCheckRequest(BaseModel):
    keyword: str
    daraz_item_id: Optional[str] = None
    product_title: Optional[str] = None
    max_pages: int = 3
    product_id: Optional[int] = None
    save_result: bool = False

class LiveCheckResult(BaseModel):
    keyword: str
    target_identifier: str
    found: bool
    page_number: Optional[int] = None
    absolute_position: Optional[int] = None
    organic_position: Optional[int] = None
    is_sponsored: bool = False
    matched_title: Optional[str] = None
    price: Optional[float] = None
    rating: Optional[float] = None
    review_count: Optional[int] = None
    product_url: Optional[str] = None
    image_url: Optional[str] = None
    roman_urdu_prompt: str
    saved_log_id: Optional[int] = None
