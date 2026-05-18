/**
 * Etapa 2 - flujo completo en App: crear, completar, eliminar.
 */
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import App from "../App";
import * as api from "../services/api";

describe("App - flujo completo", () => {
  it("crea, completa y elimina una tarea", async () => {
    const tasks: api.Task[] = [];
    let nextId = 1;

    vi.spyOn(api, "listTasks").mockImplementation(async () => tasks.map((t) => ({ ...t })));
    vi.spyOn(api, "createTask").mockImplementation(async ({ title }) => {
      const created = {
        id: nextId++,
        title,
        description: null,
        completed: false,
        created_at: new Date().toISOString(),
      };
      tasks.push(created);
      return { ...created };
    });
    vi.spyOn(api, "toggleTask").mockImplementation(async (id) => {
      const t = tasks.find((x) => x.id === id)!;
      t.completed = !t.completed;
      return { ...t };
    });
    vi.spyOn(api, "deleteTask").mockImplementation(async (id) => {
      const idx = tasks.findIndex((x) => x.id === id);
      tasks.splice(idx, 1);
    });

    const user = userEvent.setup();
    render(<App />);

    await waitFor(() => expect(screen.getByText(/Aun no hay tareas/i)).toBeInTheDocument());

    await user.type(screen.getByLabelText(/titulo de la tarea/i), "Estudiar CI/CD");
    await user.click(screen.getByRole("button", { name: /Agregar/i }));

    await waitFor(() => expect(screen.getByText("Estudiar CI/CD")).toBeInTheDocument());

    await user.click(screen.getByLabelText(/completar Estudiar/i));
    await waitFor(() =>
      expect(screen.getByText("Estudiar CI/CD").closest("li")).toHaveClass("done"),
    );

    await user.click(screen.getByLabelText(/eliminar Estudiar/i));
    await waitFor(() => expect(screen.getByText(/Aun no hay tareas/i)).toBeInTheDocument());
  });

  it("muestra error si el backend falla al listar", async () => {
    vi.spyOn(api, "listTasks").mockRejectedValueOnce(new Error("conexion rota"));
    render(<App />);
    await waitFor(() =>
      expect(screen.getByText(/No se pudieron cargar las tareas/i)).toBeInTheDocument(),
    );
  });
});
