import type { Task } from "../services/api";

interface Props {
  tasks: Task[];
  onToggle: (id: number) => void;
  onDelete: (id: number) => void;
}

export default function TaskList({ tasks, onToggle, onDelete }: Props) {
  if (tasks.length === 0) {
    return <p className="empty">Aun no hay tareas. Crea la primera.</p>;
  }
  return (
    <ul>
      {tasks.map((task) => (
        <li key={task.id} className={task.completed ? "done" : ""}>
          <input
            type="checkbox"
            checked={task.completed}
            onChange={() => onToggle(task.id)}
            aria-label={`completar ${task.title}`}
          />
          <span className="title">{task.title}</span>
          <span className="spacer" />
          <button
            type="button"
            className="danger"
            onClick={() => onDelete(task.id)}
            aria-label={`eliminar ${task.title}`}
          >
            Eliminar
          </button>
        </li>
      ))}
    </ul>
  );
}
