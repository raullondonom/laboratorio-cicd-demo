/**
 * Etapa 2 - test minimo.
 *
 * Solo verifica que la app monte y muestre el titulo. NO prueba el flujo de
 * crear/completar/eliminar tareas. Esto deja la cobertura por debajo del
 * 80% para que el PR a master falle (etapa 2 → master). La etapa 3 anadira
 * las pruebas faltantes.
 */
import { render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import App from "../App";

vi.mock("../services/api", () => ({
  listTasks: vi.fn().mockResolvedValue([]),
  createTask: vi.fn(),
  toggleTask: vi.fn(),
  deleteTask: vi.fn(),
}));

describe("App", () => {
  beforeEach(() => vi.clearAllMocks());
  afterEach(() => vi.restoreAllMocks());

  it("renderiza el titulo", async () => {
    render(<App />);
    expect(
      screen.getByRole("heading", { name: /Tareas - Laboratorio CI\/CD/i }),
    ).toBeInTheDocument();
    await waitFor(() => {
      expect(screen.getByText(/Aun no hay tareas/i)).toBeInTheDocument();
    });
  });
});
