# aumentar-cobertura/

**Etapa 2 del laboratorio.** Esta carpeta contiene SOLO pruebas adicionales. La estructura interna
replica la de `normal/`, así que para usarla basta con copiarla encima:

```powershell
# Windows PowerShell, desde la raíz del repo
Copy-Item -Recurse -Force .\aumentar-cobertura\* .\normal\
```

```bash
# Linux/Mac/Git Bash
cp -r aumentar-cobertura/* normal/
```

Después de la copia:

- `normal/backend/tests/` contiene los tests originales **y los nuevos**.
- `normal/frontend/src/__tests__/` contiene los tests originales **y los nuevos**.

Vuelve a correr `pytest --cov` y `npm run test:coverage` y la cobertura ya supera el 80 %.

> No modifiques nada del código fuente (`app/`, `src/components/`, etc.). El objetivo es **probar más**, no cambiar la implementación.
