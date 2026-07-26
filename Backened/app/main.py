from dotenv import load_dotenv
load_dotenv()  # Loads environment variables from .env file

import socketio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from apscheduler.schedulers.asyncio import AsyncIOScheduler

# Apke saare routes aur database imports
from app.database import engine, Base
from app.api import auth, assistant, quizzes, plan, courses
from app.scheduler import check_deadlines

# ==========================================
# 1. SCHEDULER SETUP
# ==========================================
scheduler = AsyncIOScheduler()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Start checking every 1 minute
    scheduler.add_job(check_deadlines, 'interval', minutes=1)
    scheduler.start()
    print("🕒 Background Scheduler Started!")
    yield
    scheduler.shutdown()

# ==========================================
# 2. FAST API INITIALIZATION
# ==========================================
fastapi_app = FastAPI(lifespan=lifespan, title="Smart Teacher Assistant Backend")

# Create Tables in PostgreSQL Database
Base.metadata.create_all(bind=engine)

# CORS Setup (Flutter app ko block hone se bachane ke liye)
fastapi_app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==========================================
# 3. ROUTES REGISTRATION (Duplicates Removed)
# ==========================================
fastapi_app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
fastapi_app.include_router(assistant.router, prefix="/api/ai", tags=["AI Assistant"])
fastapi_app.include_router(quizzes.router, prefix="/api/quizzes", tags=["Manual Quizzes"])
fastapi_app.include_router(plan.router, prefix="/api/plan", tags=["Course Plan"])
fastapi_app.include_router(courses.router, prefix="/api/courses", tags=["Courses"])

@fastapi_app.get("/")
def root():
    return {"message": "Server is Running Fast and Secure!"}

# ==========================================
# 4. SOCKET.IO REAL-TIME SERVER SETUP
# ==========================================
sio = socketio.AsyncServer(async_mode="asgi", cors_allowed_origins="*")

@sio.on("connect")
async def connect(sid, environ):
    print(f"🟢 Socket Connected: {sid}")

@sio.on("join_course_room")
async def join_course_room(sid, course_id):
    sio.enter_room(sid, f"course_{course_id}")
    print(f"📡 Socket {sid} joined room: course_{course_id}")

@sio.on("disconnect")
async def disconnect(sid):
    print(f"🔴 Socket Disconnected: {sid}")

# Wrap FastAPI app inside Socket.IO ASGI App
app = socketio.ASGIApp(sio, other_asgi_app=fastapi_app)

if __name__ == "__main__":
    import uvicorn
    # Make sure to run the wrapped 'app'
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)