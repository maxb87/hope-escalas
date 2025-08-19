import "@hotwired/turbo-rails";
import "../../javascript/controllers";
import "./application.css";

import { createRoot } from "react-dom/client";
import { Demo } from "@/components/examples/Demo";

document.addEventListener("turbo:load", () => {
  const mount = document.getElementById("react-root");
  if (mount) {
    const root = createRoot(mount);
    root.render(<Demo />);
  }
});


