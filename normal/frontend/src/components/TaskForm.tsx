import { FormEvent, useState } from "react";

interface Props {
  onCreate: (title: string) => Promise<void> | void;
}

export default function TaskForm({ onCreate }: Props) {
  const [title, setTitle] = useState("");
  const [busy, setBusy] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const value = title.trim();
    if (!value) return;
    try {
      setBusy(true);
      await onCreate(value);
      setTitle("");
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        placeholder="Nueva tarea..."
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        aria-label="titulo de la tarea"
      />
      <button type="submit" disabled={busy || title.trim().length === 0}>
        Agregar
      </button>
    </form>
  );
}
