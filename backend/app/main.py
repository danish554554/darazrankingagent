from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from .routers import products, keywords, tracker

# Create database tables automatically
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Daraz Rank & Visibility Tracking Engine",
    description="Precision organic rank tracking and testing API for Daraz sellers with Roman Urdu conversational assistance.",
    version="1.0.0"
)

# Enable CORS for Flutter app (Web, Emulator, Local Device)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(products.router)
app.include_router(keywords.router)
app.include_router(tracker.router)

@app.get("/")
def read_root():
    return {
        "status": "online",
        "service": "Daraz Rank & Visibility Tracking Engine",
        "version": "1.0.0"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}
