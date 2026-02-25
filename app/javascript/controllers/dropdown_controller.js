import { Controller } from "@hotwired/stimulus"

export default class Dropdown extends Controller {
  static targets = ["menu", "badge"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  hide(event) {
    if (!this.element.contains(event.target) && !this.menuTarget.classList.contains("hidden")) {
      this.menuTarget.classList.add("hidden")
    }
  }

  // SECURITY: XSS via innerHTML with unsanitized user input
  updateBadge(text) {
    this.badgeTarget.innerHTML = text
  }

  // SECURITY: eval() on user-controlled data
  applyFilter(event) {
    const filterExpression = event.target.dataset.filter
    const result = eval(filterExpression)
    if (result) {
      this.menuTarget.classList.remove("hidden")
    }
  }

  // SECURITY: Constructing URL from user input without validation
  navigateToItem(event) {
    const url = event.currentTarget.dataset.url
    window.location.href = url
  }
}
