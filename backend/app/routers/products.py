from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..models import Product, Keyword, SearchRankLog
from ..schemas import ProductCreate, ProductResponse

router = APIRouter(prefix="/api/products", tags=["Products"])

@router.get("", response_model=List[ProductResponse])
def get_products(db: Session = Depends(get_db)):
    return db.query(Product).all()

@router.post("", response_model=ProductResponse)
def create_product(product_in: ProductCreate, db: Session = Depends(get_db)):
    # Check if item ID already tracked
    existing = db.query(Product).filter(Product.daraz_item_id == product_in.daraz_item_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Product with this Daraz Item ID is already being tracked.")

    product = Product(
        daraz_item_id=product_in.daraz_item_id,
        sku=product_in.sku,
        title=product_in.title,
        product_url=product_in.product_url,
        image_url=product_in.image_url
    )
    db.add(product)
    db.commit()
    db.refresh(product)
    return product

@router.get("/{product_id}", response_model=ProductResponse)
def get_product(product_id: int, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

@router.delete("/{product_id}")
def delete_product(product_id: int, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    db.delete(product)
    db.commit()
    return {"message": "Product deleted successfully"}
