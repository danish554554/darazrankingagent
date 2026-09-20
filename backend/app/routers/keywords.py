from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..models import Product, Keyword, SearchRankLog
from ..schemas import KeywordCreate, KeywordResponse, SearchRankLogResponse

router = APIRouter(prefix="/api/keywords", tags=["Keywords"])

@router.get("", response_model=List[KeywordResponse])
def get_keywords(product_id: int = None, db: Session = Depends(get_db)):
    query = db.query(Keyword)
    if product_id:
        query = query.filter(Keyword.product_id == product_id)
    return query.all()

@router.post("", response_model=KeywordResponse)
def create_keyword(kw_in: KeywordCreate, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == kw_in.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    keyword = Keyword(
        product_id=kw_in.product_id,
        keyword=kw_in.keyword.strip(),
        target_rank=kw_in.target_rank,
        check_frequency_hours=kw_in.check_frequency_hours,
        is_active=kw_in.is_active
    )
    db.add(keyword)
    db.commit()
    db.refresh(keyword)
    return keyword

@router.get("/{keyword_id}/history", response_model=List[SearchRankLogResponse])
def get_keyword_history(keyword_id: int, limit: int = 50, db: Session = Depends(get_db)):
    keyword = db.query(Keyword).filter(Keyword.id == keyword_id).first()
    if not keyword:
        raise HTTPException(status_code=404, detail="Keyword not found")

    logs = (
        db.query(SearchRankLog)
        .filter(SearchRankLog.keyword_id == keyword_id)
        .order_by(SearchRankLog.recorded_at.desc())
        .limit(limit)
        .all()
    )
    return logs

@router.delete("/{keyword_id}")
def delete_keyword(keyword_id: int, db: Session = Depends(get_db)):
    keyword = db.query(Keyword).filter(Keyword.id == keyword_id).first()
    if not keyword:
        raise HTTPException(status_code=404, detail="Keyword not found")
    db.delete(keyword)
    db.commit()
    return {"message": "Keyword deleted successfully"}
