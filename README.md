# Daraz Rank Radar 🚀
**Legitimate Product Rank & Visibility Tracking Software for Daraz Sellers**

This software allows you to track, audit, and monitor your own products' organic search ranks on Daraz.pk safely and without policy-violating bot actions.

---

## 📁 Architecture Overview

```
Daraz Ranking app/
├── backend/                       # Python FastAPI Backend & SERP Engine
│   ├── app/
│   │   ├── main.py                # REST API & Router setup
│   │   ├── database.py            # SQLite / Supabase PostgreSQL connector
│   │   ├── models.py              # Product, Keyword, SearchRankLog models
│   │   ├── schemas.py             # Pydantic validation schemas
│   │   ├── services/
│   │   │   ├── daraz_crawler.py   # Headless Playwright SERP scraper
│   │   │   └── prompt_service.py  # Local Pakistani Roman Urdu prompt engine
│   │   └── routers/               # Endpoints for Products, Keywords & Live Tracker
│   ├── venv/                      # Pre-configured Python virtual environment
│   └── test_backend.py            # Self-testing verification script
├── mobile_app/                    # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart              # Entrypoint
│   │   ├── core/                  # AppTheme & ApiService
│   │   ├── models/                # Dart models matching backend schemas
│   │   ├── providers/             # State management (RankingProvider)
│   │   └── screens/
│   │       ├── dashboard_screen.dart       # Main product overview & metrics
│   │       ├── live_test_screen.dart       # Keyword search & Roman Urdu prompt modal
│   │       ├── product_detail_screen.dart  # Historical rank trend charts (fl_chart)
│   │       └── add_product_screen.dart     # Add new listing & initial keywords
├── Start_Backend.bat              # One-click backend launcher
├── Start_Flutter_Mobile.bat       # One-click Flutter app launcher
└── README.md
```

---

## 🚀 How to Run the Project

### 1. Launch the Backend Server
Double-click `Start_Backend.bat` or run:
```powershell
cd "C:\Users\danis\Desktop\Daraz Ranking app\backend"
.\venv\Scripts\activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
* **API Documentation**: Open [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs) in your browser to view and test all interactive endpoints.

### 2. Launch the Flutter Mobile App
Double-click `Start_Flutter_Mobile.bat` or run:
```powershell
cd "C:\Users\danis\Desktop\Daraz Ranking app\mobile_app"
flutter run
```
* **Mobile / Emulator Setup**: 
  * If running on the **Android Emulator**, the app automatically connects to `http://10.0.2.2:8000`.
  * If running on a **Physical Phone** connected via Wi-Fi, tap the **Settings icon** in the app's top bar and enter your computer's local IP (e.g. `http://192.168.1.100:8000`).
  * If running on **Windows Desktop** or **Chrome Web**, it defaults to `http://127.0.0.1:8000`.

---

## 🎯 How the Pakistani Roman Urdu Interactive Flow Works

1. Open the app and tap **"Live Keyword Test"**.
2. Enter your keyword (e.g., `"3 in 1 hair brush"` or `"rechargeable body hair remover"`).
3. Enter your product's **Daraz Item ID** (found in your product link `...-i123456789.html`) or a word from its title.
4. Tap **"Start Visibility Test"**.
5. Playwright crawls Daraz search results across Page 1–3 in the background.
6. When found, the app pops up a bottom sheet with natural Pakistani Roman Urdu feedback:
   > *"Zabardast! '3 in 1 Hair Brush Styler' keyword '3 in 1 hair brush' ke liye mil gaya hai.*  
   > *Page 1, Position #4 (Organic) par show ho raha hai.*  
   > *Kya iska snapshot aur rank history database mein save karni hai?"*
7. Tap **"Haan, Save Karein"** to persist the position and live price/reviews into your rank progression graph!

---

## ☁️ Future Deployment (Supabase / Render / Vercel)

The backend code is already prepared for production migration:
* **Database**: Set the `DATABASE_URL` environment variable to your Supabase PostgreSQL connection URI (`postgresql://postgres:[password]@db...supabase.co:5432/postgres`). SQLAlchemy will connect to Postgres automatically without code changes.
* **Server Hosting**: You can deploy the `backend/` folder to **Render**, **Railway**, or a cloud VPS with Docker. Playwright requires Chromium, which is already configured in the dependencies.
