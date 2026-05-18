import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import TaskList from "../components/TaskList";
import type { Task } from "../services/api";

function task(partial: Partial<Task>): Task {
  return {
    id: 1,
    title: "T",
    description: null,
    completed: false,
    created_at: "2026-01-01T00:00:00Z",
    ...partial,
  };
}

describe("TaskList", () => {
  it("muestra mensaje vacio cuando no hay tareas", () => {
    render(<TaskList tasks={[]} onToggle={vi.fn()} onDelete={vi.fn()} />);
    expect(screen.getByText(/Aun no hay tareas/i)).toBeInTheDocument();
  });

  it("renderiza una tarea pendiente y permite completarla", async () => {
    const onToggle = vi.fn();
    const onDelete = vi.fn();
    const user = userEvent.setup();
    render(
      <TaskList
        tasks={[task({ id: 5, title: "Lavar el carro" })]}
        onToggle={onToggle}
        onDelete={onDelete}
      />,
    );

    expect(screen.getByText("Lavar el carro")).toBeInTheDocument();
    await user.click(screen.getByLabelText(/completar Lavar el carro/i));
    expect(onToggle).toHaveBeenCalledWith(5);
  });

  it("renderiza una tarea completada con clase 'done'", () => {
    render(
      <TaskList
        tasks={[task({ id: 7, title: "OK", completed: true })]}
        onToggle={vi.fn()}
        onDelete={vi.fn()}
      />,
    );
    expect(screen.getByText("OK").closest("li")).toHaveClass("done");
  });

  it("permite eliminar una tarea", async () => {
    const onDelete = vi.fn();
    const user = userEvent.setup();
    render(
      <TaskList
        tasks={[task({ id: 9, title: "Borrar" })]}
        onToggle={vi.fn()}
        onDelete={onDelete}
      />,
    );
    await user.click(screen.getByLabelText(/eliminar Borrar/i));
    expect(onDelete).toHaveBeenCalledWith(9);
  });
});
