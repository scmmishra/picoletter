import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { suffix: String };

  connect() {
    this.enforce();
    this.element.addEventListener("input", this.handleInput);
    this.element.addEventListener("keydown", this.handleKeydown);
    this.element.addEventListener("select", this.clampSelection);
    this.element.addEventListener("click", this.clampCursor);
  }

  disconnect() {
    this.element.removeEventListener("input", this.handleInput);
    this.element.removeEventListener("keydown", this.handleKeydown);
    this.element.removeEventListener("select", this.clampSelection);
    this.element.removeEventListener("click", this.clampCursor);
  }

  handleInput = () => {
    this.enforce();
  };

  handleKeydown = (e) => {
    const pos = this.element.selectionStart;
    const boundary = this.boundary;

    // Block delete/backspace from removing the suffix
    if (e.key === "Delete" && pos >= boundary) {
      e.preventDefault();
    }
    if (e.key === "Backspace" && pos > boundary) {
      e.preventDefault();
    }
    // Block arrow right / end past suffix
    if (e.key === "ArrowRight" && pos >= boundary && !e.shiftKey) {
      e.preventDefault();
    }
    if (e.key === "End") {
      e.preventDefault();
      this.element.setSelectionRange(boundary, boundary);
    }
  };

  clampSelection = () => {
    requestAnimationFrame(() => this.clampCursor());
  };

  clampCursor = () => {
    const boundary = this.boundary;
    const start = Math.min(this.element.selectionStart, boundary);
    const end = Math.min(this.element.selectionEnd, boundary);
    this.element.setSelectionRange(start, end);
  };

  enforce() {
    const suffix = this.suffixValue;
    let value = this.element.value;

    // Strip suffix if present, otherwise keep only the local-part.
    if (value.endsWith(suffix)) {
      value = value.slice(0, -suffix.length);
    } else if (value.includes("@")) {
      value = value.split("@", 1)[0];
    }

    // Remove any @ the user might type
    value = value.replace(/@/g, "");

    this.element.value = value + suffix;

    // Keep cursor before the suffix
    const pos = Math.min(this.element.selectionStart, this.boundary);
    this.element.setSelectionRange(pos, pos);
  }

  get boundary() {
    return this.element.value.length - this.suffixValue.length;
  }
}
