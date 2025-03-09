import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["title", "slug"];

  initialize() {
    this.onTitleInput = () => {
      if (this.slugTarget && this.slugTarget.tagName === "INPUT") {
        this.slugTarget.value = this.slugify(this.titleTarget.value);
      } else {
        this.slugTarget.innerHTML = this.slugify(this.titleTarget.value);
      }
    };
  }
  connect() {
    this.titleTarget.addEventListener("input", this.onTitleInput);
  }

  disconnect() {
    this.titleTarget.removeEventListener("input", this.onTitleInput);
  }

  slugify(text) {
    return text
      .toString()
      .toLowerCase()
      .replace(/\s+/g, "-") // Replace spaces with -
      .replace(/[^\w-]+/g, "") // Remove all non-word chars
      .replace(/-+$/, "") // Trim - from end of text
      .replace(/^-+/, ""); // Trim - from start of text
  }
}
