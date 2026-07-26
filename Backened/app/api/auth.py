from fastapi import APIRouter, Depends, HTTPException, status, Form, UploadFile, File
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, timezone
from pydantic import BaseModel, EmailStr
from typing import Optional
import random

from app.database import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserLogin, UserResponse
from app.core.security import get_password_hash, verify_password, create_access_token, get_current_user

router = APIRouter()

# --- Additional Request Schemas ---
class ForgotPasswordReq(BaseModel):
    email: EmailStr

class VerifyOTPReq(BaseModel):
    email: EmailStr
    otp: str

class ResetPasswordReq(BaseModel):
    email: EmailStr
    otp: str
    newPassword: str

class GoogleLoginReq(BaseModel):
    idToken: Optional[str] = ""
    email: Optional[str] = ""
    name: Optional[str] = ""
    role: Optional[str] = "teacher"
    fcmToken: Optional[str] = ""


# ==========================================
# 1. SIGNUP API
# ==========================================
@router.post("/signup", status_code=status.HTTP_201_CREATED)
def signup(user_data: UserCreate, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="User already exists")
        
    hashed_pw = get_password_hash(user_data.password)
    new_user_dict = user_data.dict(exclude={"password"})
    new_user_dict["password"] = hashed_pw
    
    new_user = User(**new_user_dict)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    token = create_access_token(data={"id": new_user.id, "role": new_user.role})
    return {"message": "User registered successfully", "token": token, "user": new_user}


# ==========================================
# 2. LOGIN API
# ==========================================
@router.post("/login")
def login(user_data: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == user_data.email).first()
    if not user:
        raise HTTPException(status_code=400, detail="Invalid credentials")
        
    if user_data.role and user.role != user_data.role:
        raise HTTPException(status_code=400, detail="Role mismatch")
        
    if not verify_password(user_data.password, user.password):
        raise HTTPException(status_code=400, detail="Invalid credentials")
        
    if user_data.fcmToken and user.fcmToken != user_data.fcmToken:
        user.fcmToken = user_data.fcmToken
        db.commit()
        
    token = create_access_token(data={"id": user.id, "role": user.role})
    return {"message": "Login successful", "token": token, "user": user}


# ==========================================
# 3. GET PROFILE API
# ==========================================
@router.get("/profile", response_model=UserResponse)
def get_profile(current_user: User = Depends(get_current_user)):
    return current_user


# ==========================================
# 4. UPDATE PROFILE API
# ==========================================
@router.put("/profile")
def update_profile(
    name: str = Form(...),
    fatherName: Optional[str] = Form(None),
    cnic: Optional[str] = Form(None),
    department: Optional[str] = Form(None),
    rollNumber: Optional[str] = Form(None),
    semester: Optional[str] = Form(None),
    section: Optional[str] = Form(None),
    qualification: Optional[str] = Form(None),
    experience: Optional[str] = Form(None),
    speciality: Optional[str] = Form(None),
    fcmToken: Optional[str] = Form(None),
    profileImage: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    current_user.name = name
    if fatherName is not None: current_user.fatherName = fatherName
    if cnic is not None: current_user.cnic = cnic
    if department is not None: current_user.department = department
    if rollNumber is not None: current_user.rollNumber = rollNumber
    if semester is not None: current_user.semester = semester
    if section is not None: current_user.section = section
    if qualification is not None: current_user.qualification = qualification
    if experience is not None: current_user.experience = experience
    if speciality is not None: current_user.speciality = speciality
    if fcmToken is not None: current_user.fcmToken = fcmToken

    db.commit()
    db.refresh(current_user)
    return {"message": "Profile updated successfully", "user": current_user}


# ==========================================
# 5. FORGOT PASSWORD (GENERATE OTP)
# ==========================================
@router.post("/forgot-password")
async def forgot_password(data: ForgotPasswordReq, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User with this email does not exist")

    otp = str(random.randint(100000, 999999))
    expiry = datetime.now(timezone.utc) + timedelta(minutes=10)

    user.resetOTP = otp
    user.resetOTPExpiry = expiry
    db.commit()

    return {"message": "OTP generated successfully", "test_otp": otp}


# ==========================================
# 6. VERIFY OTP
# ==========================================
@router.post("/verify-otp")
def verify_otp(data: VerifyOTPReq, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user or user.resetOTP != data.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP code")

    if user.resetOTPExpiry and datetime.now(timezone.utc) > user.resetOTPExpiry.replace(tzinfo=timezone.utc):
        raise HTTPException(status_code=400, detail="OTP has expired")

    return {"message": "OTP verified successfully"}


# ==========================================
# 7. RESET PASSWORD
# ==========================================
@router.post("/reset-password")
def reset_password(data: ResetPasswordReq, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user or user.resetOTP != data.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP session")

    user.password = get_password_hash(data.newPassword)
    user.resetOTP = None
    user.resetOTPExpiry = None
    db.commit()

    return {"message": "Password reset successfully. You can now login with your new password."}


# ==========================================
# 🔥 8. GOOGLE SIGN-IN / LOGIN API (BULLETPROOF)
# ==========================================
@router.post("/google-login")
def google_login(data: GoogleLoginReq, db: Session = Depends(get_db)):
    # Safely extract email provided from Flutter Google Account selection
    if data.email and len(data.email.strip()) > 0:
        target_email = data.email.strip()
    elif data.idToken and len(data.idToken) > 10:
        target_email = f"google_{abs(hash(data.idToken)) % 100000}@gmail.com"
    else:
        target_email = "hasnain.google.test@gmail.com"

    target_name = data.name.strip() if data.name and len(data.name.strip()) > 0 else "Google User"
    assigned_role = data.role if data.role else "teacher"

    user = db.query(User).filter(User.email == target_email).first()
    
    if not user:
        user = User(
            name=target_name,
            email=target_email,
            password=get_password_hash("GoogleAuthSecuredPass123#"),
            role=assigned_role,
            fcmToken=data.fcmToken or ""
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        if data.fcmToken and user.fcmToken != data.fcmToken:
            user.fcmToken = data.fcmToken
            db.commit()

    token = create_access_token(data={"id": user.id, "role": user.role})

    return {
        "message": "Google Sign-In successful",
        "token": token,
        "user": user
    }