import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content", "button"]

  connect() {
    // Set up CSS for smooth height animation using interpolate-size
    this.contentTarget.style.transition = "height 0.3s ease";
    this.contentTarget.style.interpolateSize = "allow-keywords";
    this.contentTarget.style.overflow = "hidden";
    this.contentTarget.style.height = "0";
  }

  toggle() {
    const content = this.contentTarget;
    const button = this.buttonTarget;

    if (content.style.height === "0" || content.style.height === "0px") {
      // Expand to auto height
      content.style.height = "auto";
      button.textContent = "Show less";
    } else {
      // Collapse to 0
      const count = content.querySelectorAll(".flex.justify-between").length;
      content.style.height = "0";
      button.textContent = `Show ${count} more links`;
    }
  }
}
