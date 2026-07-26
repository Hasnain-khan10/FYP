from pydantic import BaseModel, EmailStr, model_validator, field_validator
from typing import Optional
from datetime import datetime
import re

# 📝 Signup Request Body
class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: str
    fcmToken: Optional[str] = ""
    
    fatherName: Optional[str] = None
    cnic: Optional[str] = None
    department: Optional[str] = None
    
    # Student Fields
    rollNumber: Optional[str] = None
    semester: Optional[str] = None
    section: Optional[str] = None
    
    # Teacher Fields
    qualification: Optional[str] = None
    experience: Optional[str] = None
    speciality: Optional[str] = None

    # 🔒 Password Validator
    @field_validator('password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters long")
        if not re.search(r'[A-Z]', v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not re.search(r'[a-z]', v):
            raise ValueError("Password must contain at least one lowercase letter")
        if not re.search(r'[0-9]', v):
            raise ValueError("Password must contain at least one digit")
        if not re.search(r'[@$!%*?&]', v):
            raise ValueError("Password must contain at least one special character (@$!%*?&)")
        return v

    # 🔥 Exact Node.js jaisi strict Validation
    @model_validator(mode='after')
    def validate_role_fields(self):
        if self.role not in ["teacher", "student"]:
            raise ValueError("Role is required and must be valid ('teacher' or 'student')")
        
        if self.role == "student":
            if not all([self.fatherName, self.rollNumber, self.semester, self.department, self.cnic, self.section]):
                raise ValueError("All student fields are required")
                
        if self.role == "teacher":
            if not all([self.fatherName, self.cnic, self.department, self.qualification, self.experience, self.speciality]):
                raise ValueError("All teacher fields are required")
                
        return self

# 🔑 Login Request Body
class UserLogin(BaseModel):
    email: EmailStr
    password: str
    role: Optional[str] = None
    fcmToken: Optional[str] = None

# 🚀 Response Body
class UserResponse(BaseModel):
    id: int
    name: str
    email: EmailStr
    role: str
    profileImage: Optional[str] = ""
    fcmToken: Optional[str] = ""
    fatherName: Optional[str] = None
    cnic: Optional[str] = None
    department: Optional[str] = None
    rollNumber: Optional[str] = None
    semester: Optional[str] = None
    section: Optional[str] = None
    qualification: Optional[str] = None
    experience: Optional[str] = None
    speciality: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True