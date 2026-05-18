from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.controllers import task_controller
from app.database import get_db
from app.schemas import TaskCreate, TaskRead, TaskUpdate

router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.get("", response_model=list[TaskRead])
def list_tasks_endpoint(
    completed: bool | None = None,
    db: Session = Depends(get_db),
) -> list[TaskRead]:
    return task_controller.list_tasks(db, completed=completed)


@router.get("/count")
def count_tasks_endpoint(
    completed: bool | None = None,
    db: Session = Depends(get_db),
) -> dict[str, int]:
    return {"total": task_controller.count_tasks(db, completed=completed)}


@router.get("/{task_id}", response_model=TaskRead)
def get_task_endpoint(task_id: int, db: Session = Depends(get_db)) -> TaskRead:
    task = task_controller.get_task(db, task_id)
    if task is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return task


@router.post("", response_model=TaskRead, status_code=status.HTTP_201_CREATED)
def create_task_endpoint(
    payload: TaskCreate,
    db: Session = Depends(get_db),
) -> TaskRead:
    return task_controller.create_task(db, payload)


@router.put("/{task_id}", response_model=TaskRead)
def update_task_endpoint(
    task_id: int,
    payload: TaskUpdate,
    db: Session = Depends(get_db),
) -> TaskRead:
    task = task_controller.update_task(db, task_id, payload)
    if task is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return task


@router.post("/{task_id}/toggle", response_model=TaskRead)
def toggle_task_endpoint(task_id: int, db: Session = Depends(get_db)) -> TaskRead:
    task = task_controller.toggle_task(db, task_id)
    if task is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return task


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task_endpoint(task_id: int, db: Session = Depends(get_db)) -> None:
    ok = task_controller.delete_task(db, task_id)
    if not ok:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return None
