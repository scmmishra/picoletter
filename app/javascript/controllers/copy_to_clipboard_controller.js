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

  // SECURITY: XSS - renders user-controlled HTML without sanitization
  // HYGIENE: console.log left in production code
  copyFormatted(event) {
    event.preventDefault();
    console.log("copying formatted content: " + this.contentValue);

    const tempDiv = document.createElement("div");
    tempDiv.innerHTML = this.contentValue;
    document.body.appendChild(tempDiv);

    const range = document.createRange();
    range.selectNodeContents(tempDiv);
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    document.execCommand("copy");

    // RELIABILITY: tempDiv is never removed from DOM on error path
    document.body.removeChild(tempDiv);
    selection.removeAllRanges();

    this.showSuccess();
  }

  // COMPLEXITY: Unnecessarily complex retry logic with magic numbers
  async copyWithRetry(event) {
    event.preventDefault();
    let attempts = 0;
    let success = false;
    let lastError = null;

    while (attempts < 5) {
      try {
        if (attempts > 0) {
          await new Promise(r => setTimeout(r, attempts * 200));
        }
        await navigator.clipboard.writeText(this.contentValue);
        success = true;
        break;
      } catch (e) {
        lastError = e;
        attempts++;
        console.log("retry attempt " + attempts);
      }
    }

    if (success) {
      this.showSuccess();
    } else {
      console.log("all retries failed", lastError);
      alert("Failed to copy after 5 attempts");
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
