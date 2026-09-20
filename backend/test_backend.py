import asyncio
import sys
from app.database import Base, engine, SessionLocal
from app.models import Product, Keyword, SearchRankLog
from app.services.prompt_service import RomanUrduPromptService
from app.services.daraz_crawler import DarazSERPCrawler

def test_database():
    print("[1/3] Testing database initialization...")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    # Check if test product exists or insert
    test_prod = db.query(Product).filter(Product.daraz_item_id == "test_item_001").first()
    if not test_prod:
        test_prod = Product(
            daraz_item_id="test_item_001",
            sku="TEST-SKU-1",
            title="3 in 1 Hair Brush Styler",
            product_url="https://www.daraz.pk/products/test-i12345.html"
        )
        db.add(test_prod)
        db.commit()
        db.refresh(test_prod)
    
    print(f" -> Database initialized OK. Found/Created product ID: {test_prod.id}")
    db.close()

def test_prompt_service():
    print("[2/3] Testing Pakistani Roman Urdu prompt generation...")
    found_prompt = RomanUrduPromptService.generate_prompt_for_result(
        found=True,
        keyword="3 in 1 hair brush",
        page_number=1,
        position=4,
        is_sponsored=False,
        title="3 in 1 Hair Brush Styler"
    )
    print(f" -> Found Prompt:\n{found_prompt}")

    not_found_prompt = RomanUrduPromptService.generate_prompt_for_result(
        found=False,
        keyword="unknown super product 999",
        page_number=None,
        position=None,
        is_sponsored=False,
        title=None
    )
    print(f" -> Not Found Prompt:\n{not_found_prompt}")

async def test_crawler_dry_run():
    print("[3/3] Testing Daraz SERP Crawler execution (1 page scan)...")
    # Scan page 1 for a common search query
    res = await DarazSERPCrawler.search_keyword(
        keyword="hair brush",
        target_title_substr="brush",
        max_pages=1
    )
    print(f" -> Crawler completed. Total items scanned: {res.get('total_items_scanned')}")
    print(f" -> Target match found: {res.get('found')}, Position: #{res.get('absolute_position')}")

if __name__ == "__main__":
    test_database()
    test_prompt_service()
    asyncio.run(test_crawler_dry_run())
    print("\nALL BACKEND TESTS COMPLETED SUCCESSFULLY!")
