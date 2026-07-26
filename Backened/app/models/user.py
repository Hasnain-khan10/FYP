from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from app.database import Base

class User(Base):
    __tablename__ = "users"

    # Core Fields
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password = Column(String, nullable=False)
    role = Column(String, nullable=False)  # "teacher" or "student"
    profileImage = Column(String, default="")
    
    # 🔥 Firebase Push Notification
    fcmToken = Column(String, default="")
    
    # Common Fields
    fatherName = Column(String, nullable=True)
    cnic = Column(String, nullable=True)
    department = Column(String, nullable=True)
    
    # 🎓 Student Specific Fields
    rollNumber = Column(String, nullable=True)
    semester = Column(String, nullable=True)
    section = Column(String, nullable=True)
    
    # 👨‍🏫 Teacher Specific Fields
    qualification = Column(String, nullable=True)
    experience = Column(String, nullable=True)
    speciality = Column(String, nullable=True)
    
    # 🔐 OTP Password Reset Fields
    resetOTP = Column(String, nullable=True)
    resetOTPExpiry = Column(DateTime(timezone=True), nullable=True)
    
    # Timestamps (Mongoose timestamps: true ka alternative)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())