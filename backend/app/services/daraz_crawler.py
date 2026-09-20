import asyncio
import json
import logging
import re
import urllib.parse
from typing import Optional, Dict, Any, List
from playwright.async_api import async_playwright

logger = logging.getLogger("daraz_crawler")

class DarazSERPCrawler:
    """
    Precision crawler for tracking organic search ranks on Daraz.pk.
    Extracts page number, position index, price, ratings, and sponsored tags.
    """

    @staticmethod
    def _clean_price(price_str: Optional[str]) -> Optional[float]:
        if not price_str:
            return None
        try:
            # Remove Rs. and commas: "Rs. 1,450" -> 1450.0
            cleaned = re.sub(r"[^\d.]", "", price_str)
            return float(cleaned) if cleaned else None
        except Exception:
            return None

    @classmethod
    async def search_keyword(
        cls,
        keyword: str,
        target_item_id: Optional[str] = None,
        target_title_substr: Optional[str] = None,
        max_pages: int = 3
    ) -> Dict[str, Any]:
        """
        Searches Daraz for the keyword across up to max_pages.
        Returns detailed location of the target product if found.
        """
        target_item_id = str(target_item_id).strip() if target_item_id else None
        target_title_substr = target_title_substr.lower().strip() if target_title_substr else None

        result = {
            "found": False,
            "keyword": keyword,
            "target_item_id": target_item_id,
            "page_number": None,
            "absolute_position": None,
            "organic_position": None,
            "is_sponsored": False,
            "matched_title": None,
            "price": None,
            "rating": None,
            "review_count": None,
            "product_url": None,
            "image_url": None,
            "total_items_scanned": 0
        }

        async with async_playwright() as p:
            # Launch browser with anti-detection configurations (standard user agents)
            browser = await p.chromium.launch(headless=True)
            context = await browser.new_context(
                user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
                viewport={"width": 1366, "height": 768},
                locale="en-US"
            )

            total_scanned = 0
            cumulative_organic = 0

            for page_num in range(1, max_pages + 1):
                page = await context.new_page()
                encoded_kw = urllib.parse.quote(keyword)
                url = f"https://www.daraz.pk/catalog/?q={encoded_kw}&page={page_num}"
                
                try:
                    await page.goto(url, wait_until="domcontentloaded", timeout=25000)
                    # Allow hydration script to render cards
                    await asyncio.sleep(2)
                except Exception as e:
                    logger.warning(f"Error loading {url}: {e}")
                    await page.close()
                    continue

                # Strategy 1: Extract from window.pageData JSON if present
                items_data = []
                try:
                    page_data = await page.evaluate("() => window.pageData || null")
                    if page_data and "mods" in page_data and "listItems" in page_data["mods"]:
                        items_data = page_data["mods"]["listItems"]
                except Exception:
                    pass

                # Strategy 2: Extract directly from DOM if pageData not accessible
                if not items_data:
                    try:
                        cards = await page.query_selector_all('[data-item-id], [data-qa-locator="product-item"]')
                        for card in cards:
                            item_id = await card.get_attribute("data-item-id")
                            
                            # Title
                            title_el = await card.query_selector('a[title], [data-qa-locator="product-title"], .title--wF493')
                            title = await title_el.inner_text() if title_el else ""
                            
                            # Link
                            link = await card.query_selector('a[href*="/products/"]')
                            href = await link.get_attribute("href") if link else ""
                            if href and not href.startswith("http"):
                                href = f"https:{href}"

                            # Image
                            img_el = await card.query_selector('img')
                            img_src = await img_el.get_attribute("src") if img_el else None

                            # Price
                            price_el = await card.query_selector('.price--NVB62, [data-qa-locator="product-price"]')
                            price_text = await price_el.inner_text() if price_el else ""

                            # Check for ad tag
                            ad_el = await card.query_selector('.ad-flag, [data-tracking="ad"]')
                            is_ad = ad_el is not None

                            items_data.append({
                                "itemId": item_id,
                                "title": title,
                                "itemUrl": href,
                                "image": img_src,
                                "price": price_text,
                                "isSponsored": is_ad
                            })
                    except Exception as e:
                        logger.warning(f"DOM extraction error on page {page_num}: {e}")

                # Process all items on this page
                page_pos = 0
                for item in items_data:
                    page_pos += 1
                    total_scanned += 1

                    item_id_str = str(item.get("itemId") or "").strip()
                    title_str = str(item.get("title") or "").strip()
                    is_ad = bool(item.get("isSponsored") or item.get("adFlag") or False)

                    if not is_ad:
                        cumulative_organic += 1

                    # Match condition
                    matched = False
                    if target_item_id and item_id_str == target_item_id:
                        matched = True
                    elif target_title_substr and target_title_substr in title_str.lower():
                        matched = True

                    if matched:
                        raw_price = item.get("priceShow") or item.get("price") or ""
                        price_num = cls._clean_price(str(raw_price))
                        item_url = item.get("itemUrl") or item.get("productUrl") or ""
                        if item_url and not item_url.startswith("http"):
                            item_url = f"https:{item_url}"

                        result.update({
                            "found": True,
                            "page_number": page_num,
                            "absolute_position": page_pos,
                            "organic_position": cumulative_organic if not is_ad else None,
                            "is_sponsored": is_ad,
                            "matched_title": title_str,
                            "price": price_num,
                            "rating": float(item.get("ratingScore", 0)) if item.get("ratingScore") else None,
                            "review_count": int(item.get("review", 0)) if item.get("review") else None,
                            "product_url": item_url,
                            "image_url": item.get("image"),
                            "total_items_scanned": total_scanned
                        })
                        await page.close()
                        await browser.close()
                        return result

                await page.close()
                await asyncio.sleep(1)

            await browser.close()
            result["total_items_scanned"] = total_scanned
            return result
