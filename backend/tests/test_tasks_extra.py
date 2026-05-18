"""
Etapa 2 - Tests adicionales que llevan la cobertura por encima del 80 %.

Cubre:
  * listar tareas (vacio y con filtro completed)
  * obtener tarea por id (200 y 404)
  * actualizar tarea (200, 404 y campos parciales)
  * toggle (200 y 404)
  * eliminar tarea (204 y 404)
  * contador (sin y con filtro)
  * helpers de dominio del modelo (mark_completed / mark_pending)
"""


def _create(client, title="t", description=None, completed=False):
    return client.post(
        "/tasks",
        json={"title": title, "description": description, "completed": completed},
    ).json()


def test_list_empty(client):
    response = client.get("/tasks")
    assert response.status_code == 200
    assert response.json() == []


def test_list_filter_completed(client):
    _create(client, title="A", completed=False)
    b = _create(client, title="B", completed=True)

    only_done = client.get("/tasks?completed=true").json()
    assert [t["id"] for t in only_done] == [b["id"]]

    only_pending = client.get("/tasks?completed=false").json()
    assert [t["title"] for t in only_pending] == ["A"]


def test_get_by_id_ok_and_404(client):
    created = _create(client, title="X")
    ok = client.get(f"/tasks/{created['id']}")
    assert ok.status_code == 200
    assert ok.json()["title"] == "X"

    miss = client.get("/tasks/9999")
    assert miss.status_code == 404
    assert miss.json()["detail"] == "Task not found"


def test_update_partial_and_404(client):
    created = _create(client, title="orig", description="d")
    response = client.put(
        f"/tasks/{created['id']}",
        json={"title": "renombrado", "completed": True},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["title"] == "renombrado"
    assert body["completed"] is True
    assert body["description"] == "d"  # no se toco

    # 404
    missing = client.put("/tasks/9999", json={"title": "x"})
    assert missing.status_code == 404


def test_update_uncomplete(client):
    created = _create(client, title="A", completed=True)
    response = client.put(f"/tasks/{created['id']}", json={"completed": False})
    assert response.status_code == 200
    assert response.json()["completed"] is False


def test_toggle_ok_and_404(client):
    created = _create(client, title="A")
    first = client.post(f"/tasks/{created['id']}/toggle").json()
    assert first["completed"] is True
    second = client.post(f"/tasks/{created['id']}/toggle").json()
    assert second["completed"] is False

    miss = client.post("/tasks/9999/toggle")
    assert miss.status_code == 404


def test_delete_ok_and_404(client):
    created = _create(client, title="del")
    deleted = client.delete(f"/tasks/{created['id']}")
    assert deleted.status_code == 204

    missing = client.delete(f"/tasks/{created['id']}")
    assert missing.status_code == 404


def test_count_endpoint(client):
    _create(client, title="A", completed=False)
    _create(client, title="B", completed=True)
    _create(client, title="C", completed=True)

    total = client.get("/tasks/count").json()
    assert total == {"total": 3}

    done = client.get("/tasks/count?completed=true").json()
    assert done == {"total": 2}

    pending = client.get("/tasks/count?completed=false").json()
    assert pending == {"total": 1}


def test_model_helpers():
    from app.models import Task

    t = Task(title="t")
    assert t.completed in (False, None)
    t.mark_completed()
    assert t.completed is True
    t.mark_pending()
    assert t.completed is False


def test_create_validation_error(client):
    # title vacio dispara 422 (Pydantic)
    response = client.post("/tasks", json={"title": ""})
    assert response.status_code == 422
