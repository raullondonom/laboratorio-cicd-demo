/**
 * Etapa 1 - test minimo del frontend.
 *
 * Cobertura intencionalmente baja: solo verifica que la app monte y muestre el
 * titulo. No prueba creacion, toggle ni eliminacion. La Etapa 2 anade el resto
 * desde `aumentar-cobertura/`.
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
