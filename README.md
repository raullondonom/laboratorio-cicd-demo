# Laboratorio CI/CD — FastAPI + React + PostgreSQL + SonarCloud + GitHub Actions

Laboratorio en parejas para practicar **integración continua, análisis estático y gates de cobertura**.

> 📘 **La guía completa con teoría, capturas requeridas y paso a paso está en [`guia.html`](./guia.html)**. Ábrela con doble clic (no necesita servidor).

## Inicio rápido

```powershell
# 1. Preparar el entorno (instala Python 3.12.10, Node 20, gh)
powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows.ps1

# 2. Copiar variables y levantar todo
Copy-Item .env.example .env
docker compose up -d --build

# 3. Verificar
#   Frontend: http://localhost:5173
#   API:      http://localhost:8000/docs
#   pgAdmin:  http://localhost:5050
```

## Estructura

```
.
├── guia.html                 # GUÍA DEL LABORATORIO (abrir en navegador)
├── scripts/setup-windows.ps1 # preparación de PC (Python/Node/gh)
├── docker-compose.yml        # backend + frontend + postgres + pgadmin
├── normal/                   # ETAPA 1 — código + tests insuficientes (PR falla)
│   ├── backend/              #   FastAPI MVC
│   └── frontend/             #   React + Vite + TS
├── aumentar-cobertura/       # ETAPA 2 — pruebas para pegar encima de normal/
├── sonar-project.properties  # configuración SonarCloud
└── .github/workflows/        # ci-develop.yml y ci-master.yml
```

## Flujo del laboratorio (resumen)

1. Clonar como repo **público** en GitHub. Crear ramas `develop` y `master` y protegerlas.
2. Conectar el repo a SonarCloud, obtener `SONAR_TOKEN`, agregarlo como secret.
3. **Etapa 1**: abrir PR a `develop` (pasa) → abrir PR a `master` (falla por cobertura y Quality Gate).
4. **Etapa 2**: copiar `aumentar-cobertura/*` sobre `normal/`, abrir PR a `master` (pasa).
5. Entregar **PDF** con 20 capturas de pantalla completa + explicación de cada una. Detalle en la guía.

## Comandos útiles

| Acción | Comando |
|--------|---------|
| Tests backend con cobertura | `cd normal/backend && pytest --cov=app --cov-fail-under=80` |
| Lint backend | `cd normal/backend && ruff check app` |
| Tests frontend con cobertura | `cd normal/frontend && npm run test:coverage` |
| Lint frontend | `cd normal/frontend && npm run lint` |
| Reset de BD | `docker compose down -v && docker compose up -d` |
