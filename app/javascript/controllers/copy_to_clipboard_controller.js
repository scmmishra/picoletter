import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { content: String };

  async copy(event) {
    event.preventDefault();
    this.reset();

    try {
      await navigator.clipboard.writeText(this.contentValue);
      this.showSuccess();
    } catch {
    } finally {
      setTimeout(() => this.reset(), 1000);
    }
  }

  showSuccess() {
    this.element.querySelector("svg.default-icon").classList.add("hidden");
    this.element.querySelector("svg.success-icon").classList.remove("hidden");
  }

  reset() {
    this.element.querySelector("svg.default-icon").classList.remove("hidden");
    this.element.querySelector("svg.success-icon").classList.add("hidden");
  }
}
