from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import Task
from app.schemas import TaskCreate, TaskUpdate


def list_tasks(db: Session, *, completed: bool | None = None) -> list[Task]:
    stmt = select(Task).order_by(Task.id)
    if completed is not None:
        stmt = stmt.where(Task.completed == completed)
    return list(db.scalars(stmt).all())


def get_task(db: Session, task_id: int) -> Task | None:
    return db.get(Task, task_id)


def create_task(db: Session, data: TaskCreate) -> Task:
    task = Task(
        title=data.title,
        description=data.description,
        completed=data.completed,
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


def update_task(db: Session, task_id: int, data: TaskUpdate) -> Task | None:
    task = get_task(db, task_id)
    if task is None:
        return None
    if data.title is not None:
        task.title = data.title
    if data.description is not None:
        task.description = data.description
    if data.completed is not None:
        if data.completed:
            task.mark_completed()
        else:
            task.mark_pending()
    db.commit()
    db.refresh(task)
    return task


def delete_task(db: Session, task_id: int) -> bool:
    task = get_task(db, task_id)
    if task is None:
        return False
    db.delete(task)
    db.commit()
    return True


def count_tasks(db: Session, *, completed: bool | None = None) -> int:
    stmt = select(func.count(Task.id))
    if completed is not None:
        stmt = stmt.where(Task.completed == completed)
    return int(db.scalar(stmt) or 0)


def toggle_task(db: Session, task_id: int) -> Task | None:
    task = get_task(db, task_id)
    if task is None:
        return None
    if task.completed:
        task.mark_pending()
    else:
        task.mark_completed()
    db.commit()
    db.refresh(task)
    return task
