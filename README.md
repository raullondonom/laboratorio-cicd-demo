# Laboratorio CI/CD — FastAPI + React + PostgreSQL + SonarCloud + GitHub Actions

Repositorio del laboratorio para practicar integración continua, análisis estático y
gates de cobertura. **Estado actual: Etapa 1** (scaffolding + app trivial).

> 📘 **Guía completa con teoría, pasos y capturas requeridas: [`guia.html`](./guia.html)** (abrir con doble clic, no necesita servidor).

## Inicio rápido

```powershell
# 1. Preparar el PC (Python 3.12.10, Node 20.11.1, gh CLI, validar Docker)
powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows.ps1

# 2. Levantar la infraestructura
Copy-Item .env.example .env
docker compose up -d --build

# 3. Verificar
#   Frontend:  http://localhost:5173
#   API:       http://localhost:8000/docs
#   pgAdmin:   http://localhost:5050
```

## Estructura del repositorio (Etapa 1)

```
.
├── README.md
├── guia.html                       # GUÍA INTERACTIVA del laboratorio
├── scripts/setup-windows.ps1
├── docker-compose.yml              # 4 servicios: backend, frontend, db, pgadmin
├── .env.example
├── sonar-project.properties        # config SonarCloud
├── backend/                        # FastAPI - solo endpoint /health
│   ├── app/
│   ├── tests/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── pyproject.toml
├── frontend/                       # React + Vite + TS - solo pantalla "Hello"
│   ├── src/
│   ├── package.json
│   └── Dockerfile
└── .github/workflows/
    ├── ci-develop.yml              # PR → develop: lint + tests + build
    └── ci-master.yml               # PR → master: lint + cobertura ≥80% + Sonar + docker
```

## Cómo progresar a las siguientes etapas

Tu profesor te entregará **dos carpetas adicionales** al lado de este repo:

```
Laboratorio CI CD/                  ← carpeta contenedora del kit (no es repo)
├── laboratorio-cicd-demo/          ← este repo (estado actual: Etapa 1)
├── etapa-2/                        ← overlay para Etapa 2 (CRUD)
└── etapa-3/                        ← overlay para Etapa 3 (tests adicionales)
```

### Etapa 2 — agregar el CRUD de tareas (sin tests nuevos)

Esta etapa **debe fallar** el pipeline a `master` por cobertura insuficiente.

```powershell
# Desde la raíz del repo
git checkout develop
git checkout -b feature/etapa-2-crud
Copy-Item -Recurse -Force ..\etapa-2\* .
git add .
git commit -m "etapa 2: agregar CRUD de tareas"
git push -u origin feature/etapa-2-crud
# Abre PR feature/etapa-2-crud → develop (pasa)
# Tras mergear, abre PR develop → master (debe FALLAR)
```

### Etapa 3 — agregar los tests faltantes

Esta etapa **debe pasar** el pipeline porque la cobertura sube por encima del 80 %.

```powershell
git checkout develop
git checkout -b feature/etapa-3-tests
Copy-Item -Recurse -Force ..\etapa-3\* .
git add .
git commit -m "etapa 3: agregar tests para alcanzar cobertura"
git push -u origin feature/etapa-3-tests
# PR feature/etapa-3-tests → develop (pasa)
# Tras mergear, reabre o actualiza el PR develop → master (ahora PASA)
```

## Comandos útiles

| Acción | Comando |
|--------|---------|
| Tests backend con cobertura | `cd backend && pytest --cov=app --cov-fail-under=80` |
| Lint backend | `cd backend && ruff check app` |
| Tests frontend con cobertura | `cd frontend && npm run test:coverage` |
| Lint frontend | `cd frontend && npm run lint` |
| Reset BD | `docker compose down -v && docker compose up -d` |
