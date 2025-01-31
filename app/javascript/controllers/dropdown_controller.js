import { Controller } from "@hotwired/stimulus"

export default class Dropdown extends Controller {
  static targets = ["menu"]

  // connect() {
  //   useTransition(this, {
  //     element: this.menuTarget,
  //   })
  // }

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  hide(event) {
    if (!this.element.contains(event.target) && !this.menuTarget.classList.contains("hidden")) {
      this.menuTarget.classList.add("hidden")
    }
  }
}
