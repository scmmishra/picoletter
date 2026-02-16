import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "showIcon", "hideIcon"]

  toggle() {
    const hidden = this.inputTarget.type === "password"
    this.inputTarget.type = hidden ? "text" : "password"
    this.showIconTarget.classList.toggle("hidden", hidden)
    this.hideIconTarget.classList.toggle("hidden", !hidden)
  }
}
