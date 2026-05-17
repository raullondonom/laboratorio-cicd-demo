"""
Etapa 1 - Tests minimos.

Estos tests dejan el proyecto con cobertura POR DEBAJO del 80% a proposito,
para que el estudiante observe que el pipeline en `master` rechaza el PR.
En la Etapa 2 se completaran las pruebas faltantes desde `aumentar-cobertura/`.
"""


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_create_task(client):
    payload = {"title": "Mi primera tarea", "description": "demo"}
    response = client.post("/tasks", json=payload)
    assert response.status_code == 201
    body = response.json()
    assert body["title"] == "Mi primera tarea"
    assert body["completed"] is False
    assert "id" in body
