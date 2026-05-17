import axios from "axios";

export interface Task {
  id: number;
  title: string;
  description: string | null;
  completed: boolean;
  created_at: string;
}

export interface TaskCreatePayload {
  title: string;
  description?: string | null;
}

const baseURL = (import.meta.env.VITE_API_URL as string | undefined) ?? "http://localhost:8000";

export const http = axios.create({ baseURL, timeout: 10_000 });

export async function listTasks(): Promise<Task[]> {
  const { data } = await http.get<Task[]>("/tasks");
  return data;
}

export async function createTask(payload: TaskCreatePayload): Promise<Task> {
  const { data } = await http.post<Task>("/tasks", payload);
  return data;
}

export async function toggleTask(id: number): Promise<Task> {
  const { data } = await http.post<Task>(`/tasks/${id}/toggle`);
  return data;
}

export async function deleteTask(id: number): Promise<void> {
  await http.delete(`/tasks/${id}`);
}

export async function countTasks(): Promise<number> {
  const { data } = await http.get<{ total: number }>("/tasks/count");
  return data.total;
}
