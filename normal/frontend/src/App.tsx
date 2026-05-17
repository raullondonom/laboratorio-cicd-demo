import { useCallback, useEffect, useState } from "react";

import TaskForm from "./components/TaskForm";
import TaskList from "./components/TaskList";
import {
  createTask,
  deleteTask,
  listTasks,
  toggleTask,
  type Task,
} from "./services/api";

export default function App() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    try {
      const data = await listTasks();
      setTasks(data);
      setError(null);
    } catch (err) {
      setError(`No se pudieron cargar las tareas: ${(err as Error).message}`);
    }
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  async function handleCreate(title: string) {
    await createTask({ title });
    await refresh();
  }

  async function handleToggle(id: number) {
    await toggleTask(id);
    await refresh();
  }

  async function handleDelete(id: number) {
    await deleteTask(id);
    await refresh();
  }

  return (
    <div className="container">
      <h1>Tareas - Laboratorio CI/CD</h1>
      <TaskForm onCreate={handleCreate} />
      {error && <p style={{ color: "crimson" }}>{error}</p>}
      <TaskList tasks={tasks} onToggle={handleToggle} onDelete={handleDelete} />
    </div>
  );
}
