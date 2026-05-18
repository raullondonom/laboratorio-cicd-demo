import { describe, expect, it, vi, beforeEach } from "vitest";

import * as api from "../services/api";

describe("services/api", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it("listTasks devuelve el array recibido", async () => {
    vi.spyOn(api.http, "get").mockResolvedValueOnce({
      data: [{ id: 1, title: "x", description: null, completed: false, created_at: "z" }],
    } as any);
    const result = await api.listTasks();
    expect(result).toHaveLength(1);
    expect(result[0].title).toBe("x");
  });

  it("createTask hace POST a /tasks", async () => {
    const post = vi.spyOn(api.http, "post").mockResolvedValueOnce({
      data: { id: 2, title: "n", description: null, completed: false, created_at: "z" },
    } as any);
    const created = await api.createTask({ title: "n" });
    expect(post).toHaveBeenCalledWith("/tasks", { title: "n" });
    expect(created.id).toBe(2);
  });

  it("toggleTask hace POST a /tasks/:id/toggle", async () => {
    const post = vi.spyOn(api.http, "post").mockResolvedValueOnce({
      data: { id: 3, title: "t", description: null, completed: true, created_at: "z" },
    } as any);
    const updated = await api.toggleTask(3);
    expect(post).toHaveBeenCalledWith("/tasks/3/toggle");
    expect(updated.completed).toBe(true);
  });

  it("deleteTask hace DELETE a /tasks/:id", async () => {
    const del = vi.spyOn(api.http, "delete").mockResolvedValueOnce({ data: undefined } as any);
    await api.deleteTask(4);
    expect(del).toHaveBeenCalledWith("/tasks/4");
  });

  it("countTasks devuelve el total", async () => {
    vi.spyOn(api.http, "get").mockResolvedValueOnce({ data: { total: 7 } } as any);
    expect(await api.countTasks()).toBe(7);
  });
});
