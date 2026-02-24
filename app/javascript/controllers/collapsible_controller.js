import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content", "icon", "button"]
  static values = {
    expandedText: String,
    collapsedText: String,
  }

  connect() {
    this.contentTarget.style.transition = "height 0.3s ease";
    this.contentTarget.style.interpolateSize = "allow-keywords";
    this.contentTarget.style.overflow = "hidden";
    this.contentTarget.style.height = "0";
  }

  toggle() {
    const isCollapsed = this.contentTarget.style.height === "0" || this.contentTarget.style.height === "0px";
    this.contentTarget.style.height = isCollapsed ? "auto" : "0";

    if (this.hasIconTarget) {
      this.iconTarget.style.transition = "transform 0.2s ease";
      this.iconTarget.style.transform = isCollapsed ? "rotate(90deg)" : "rotate(0deg)";
    }

    if (this.hasButtonTarget) {
      this.buttonTarget.textContent = isCollapsed ? this.expandedTextValue : this.collapsedTextValue;
    }
  }
}
