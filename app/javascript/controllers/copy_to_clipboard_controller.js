import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { content: String };

  async copy(event) {
    event.preventDefault();

    try {
      await navigator.clipboard.writeText(this.contentValue);
    } catch {}
  }
}
