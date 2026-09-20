from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional

from ..database import get_db
from ..models import Product, Keyword, SearchRankLog
from ..schemas import LiveCheckRequest, LiveCheckResult, SearchRankLogCreate, SearchRankLogResponse
from ..services.daraz_crawler import DarazSERPCrawler
from ..services.prompt_service import RomanUrduPromptService

router = APIRouter(prefix="/api/tracker", tags=["Tracker"])

@router.post("/live-check", response_model=LiveCheckResult)
async def perform_live_check(req: LiveCheckRequest, db: Session = Depends(get_db)):
    """
    Runs an on-demand live rank search for a keyword and checks for target product.
    Generates Pakistani Roman Urdu conversational prompt for the user.
    """
    target_id = req.daraz_item_id
    target_title = req.product_title

    # If product_id given, lookup product details
    product = None
    if req.product_id:
        product = db.query(Product).filter(Product.id == req.product_id).first()
        if product:
            target_id = product.daraz_item_id
            target_title = target_title or product.title

    # Perform SERP crawl
    crawl_result = await DarazSERPCrawler.search_keyword(
        keyword=req.keyword,
        target_item_id=target_id,
        target_title_substr=target_title,
        max_pages=req.max_pages
    )

    found = crawl_result["found"]
    page_num = crawl_result["page_number"]
    pos = crawl_result["absolute_position"]
    is_sponsored = crawl_result["is_sponsored"]
    matched_title = crawl_result.get("matched_title") or target_title

    # Generate Roman Urdu conversational question
    prompt_msg = RomanUrduPromptService.generate_prompt_for_result(
        found=found,
        keyword=req.keyword,
        page_number=page_num,
        position=pos,
        is_sponsored=is_sponsored,
        title=matched_title
    )

    saved_log_id = None
    if req.save_result and product:
        # Find or create keyword for product
        kw_record = (
            db.query(Keyword)
            .filter(Keyword.product_id == product.id, Keyword.keyword == req.keyword.strip())
            .first()
        )
        if not kw_record:
            kw_record = Keyword(
                product_id=product.id,
                keyword=req.keyword.strip(),
                target_rank=10
            )
            db.add(kw_record)
            db.commit()
            db.refresh(kw_record)

        log = SearchRankLog(
            keyword_id=kw_record.id,
            page_number=page_num,
            absolute_position=pos,
            organic_position=crawl_result.get("organic_position"),
            is_sponsored=is_sponsored,
            price=crawl_result.get("price"),
            rating=crawl_result.get("rating"),
            review_count=crawl_result.get("review_count"),
            found=found,
            notes="Manual live test scan"
        )
        db.add(log)
        db.commit()
        db.refresh(log)
        saved_log_id = log.id

    return LiveCheckResult(
        keyword=req.keyword,
        target_identifier=str(target_id or target_title or "Unknown"),
        found=found,
        page_number=page_num,
        absolute_position=pos,
        organic_position=crawl_result.get("organic_position"),
        is_sponsored=is_sponsored,
        matched_title=matched_title,
        price=crawl_result.get("price"),
        rating=crawl_result.get("rating"),
        review_count=crawl_result.get("review_count"),
        product_url=crawl_result.get("product_url"),
        image_url=crawl_result.get("image_url"),
        roman_urdu_prompt=prompt_msg,
        saved_log_id=saved_log_id
    )

@router.post("/save-log", response_model=SearchRankLogResponse)
def save_rank_log(log_in: SearchRankLogCreate, db: Session = Depends(get_db)):
    """
    Manually save a confirmed rank log entry after the user clicks 'Save Karein'.
    """
    log = SearchRankLog(
        keyword_id=log_in.keyword_id,
        page_number=log_in.page_number,
        absolute_position=log_in.absolute_position,
        organic_position=log_in.organic_position,
        is_sponsored=log_in.is_sponsored,
        price=log_in.price,
        rating=log_in.rating,
        review_count=log_in.review_count,
        found=log_in.found,
        notes=log_in.notes or "Saved via user confirmation"
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return log
