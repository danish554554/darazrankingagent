import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from .database import Base

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    daraz_item_id = Column(String(64), index=True, nullable=False)
    sku = Column(String(64), nullable=True)
    title = Column(String(255), nullable=False)
    product_url = Column(Text, nullable=False)
    image_url = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    keywords = relationship("Keyword", back_populates="product", cascade="all, delete-orphan")


class Keyword(Base):
    __tablename__ = "keywords"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    keyword = Column(String(255), index=True, nullable=False)
    target_rank = Column(Integer, default=10)
    check_frequency_hours = Column(Integer, default=12)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    product = relationship("Product", back_populates="keywords")
    rank_logs = relationship("SearchRankLog", back_populates="keyword_ref", cascade="all, delete-orphan")


class SearchRankLog(Base):
    __tablename__ = "search_rank_logs"

    id = Column(Integer, primary_key=True, index=True)
    keyword_id = Column(Integer, ForeignKey("keywords.id"), nullable=False)
    recorded_at = Column(DateTime, default=datetime.datetime.utcnow)
    page_number = Column(Integer, nullable=True)
    absolute_position = Column(Integer, nullable=True)
    organic_position = Column(Integer, nullable=True)
    is_sponsored = Column(Boolean, default=False)
    price = Column(Float, nullable=True)
    rating = Column(Float, nullable=True)
    review_count = Column(Integer, nullable=True)
    found = Column(Boolean, default=False)
    notes = Column(Text, nullable=True)

    keyword_ref = relationship("Keyword", back_populates="rank_logs")
