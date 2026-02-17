import { Controller } from "@hotwired/stimulus";

let shikiPromise = null;

function loadShiki() {
  if (!shikiPromise) {
    shikiPromise = import("https://esm.sh/shiki@3.22.0");
  }
  return shikiPromise;
}

export default class extends Controller {
  static values = { lang: String, code: String };
  static targets = ["container"];

  async connect() {
    try {
      const { codeToHtml } = await loadShiki();
      // NOTE: The innerHTML usage below is intentional for Shiki syntax highlighting of trusted, server-rendered content
      this.containerTarget.innerHTML = await codeToHtml(this.codeValue, {
        lang: this.langValue,
        theme: "github-light",
      });
    } catch (error) {
      console.error(error);
      console.log("Shiki failed to load, using fallback rendering");
    }
  }
}
