import os
from pathlib import Path
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from dotenv import load_dotenv

# 🎯 Project Root Path dynamically calculate karein (BACKENED folder)
BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / ".env"

# Explicitly load .env file from exact absolute path
load_dotenv(dotenv_path=ENV_PATH, override=True)

# Directly get DATABASE_URL
DATABASE_URL = os.getenv("DATABASE_URL")

# Debug prints
print(f"📁 LOOKING FOR .ENV AT: {ENV_PATH}")
print(f"👉 LOADED DATABASE URL: {DATABASE_URL}")

if not DATABASE_URL:
    raise ValueError(f"❌ DATABASE_URL is missing! Checked at: {ENV_PATH}")

# 🔥 FIX: Added pool_pre_ping, pool_recycle, pool_size to prevent SSL Closed Unexpectedly error
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,  # Checks connection before executing query
    pool_recycle=300,     # Recycles connection every 5 minutes
    pool_size=10,
    max_overflow=20
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()