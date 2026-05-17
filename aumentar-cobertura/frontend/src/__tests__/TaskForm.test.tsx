import { fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import TaskForm from "../components/TaskForm";

describe("TaskForm", () => {
  it("deshabilita el boton si el titulo esta vacio", () => {
    render(<TaskForm onCreate={vi.fn()} />);
    expect(screen.getByRole("button", { name: /Agregar/i })).toBeDisabled();
  });

  it("invoca onCreate y limpia el input al enviar", async () => {
    const user = userEvent.setup();
    const handler = vi.fn().mockResolvedValue(undefined);
    render(<TaskForm onCreate={handler} />);

    const input = screen.getByLabelText(/titulo de la tarea/i);
    await user.type(input, "Comprar pan");
    await user.click(screen.getByRole("button", { name: /Agregar/i }));

    expect(handler).toHaveBeenCalledWith("Comprar pan");
    expect(input).toHaveValue("");
  });

  it("no envia si el titulo solo tiene espacios", () => {
    const handler = vi.fn();
    render(<TaskForm onCreate={handler} />);

    const form = screen.getByRole("button", { name: /Agregar/i }).closest("form")!;
    fireEvent.submit(form);
    expect(handler).not.toHaveBeenCalled();
  });
});
