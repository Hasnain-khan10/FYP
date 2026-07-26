from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.plan import WeekPlan

router = APIRouter()

# GET PLAN BY COURSE
@router.get("/course/{course_id}")
async def get_plan_by_course(course_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    plan = db.query(WeekPlan).filter(WeekPlan.course_id == course_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="No weekly plan found for this course")
    return {"success": True, "plan": plan}

# DELETE PLAN
@router.delete("/{plan_id}")
async def delete_plan(plan_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    plan = db.query(WeekPlan).filter(WeekPlan.id == plan_id, WeekPlan.teacher_id == current_user.id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    db.delete(plan)
    db.commit()
    return {"success": True, "message": "Plan deleted successfully"}