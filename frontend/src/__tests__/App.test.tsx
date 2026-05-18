import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import App from "../App";

describe("App", () => {
  it("renderiza el titulo del laboratorio", () => {
    render(<App />);
    expect(
      screen.getByRole("heading", { name: /Laboratorio CI\/CD/i }),
    ).toBeInTheDocument();
  });
});
