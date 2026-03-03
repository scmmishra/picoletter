import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "nav", "deck"]

  connect() {
    this.index = 0
    this.arrange(false)
  }

  next() {
    const total = this.cardTargets.length
    if (total <= 1) return
    this.index = (this.index + 1) % total
    this.arrange()
  }

  prev() {
    const total = this.cardTargets.length
    if (total <= 1) return
    this.index = (this.index - 1 + total) % total
    this.arrange()
  }

  arrange(animate = true) {
    const cards = this.cardTargets
    const total = cards.length

    this.element.classList.toggle("hidden", total === 0)

    if (this.hasNavTarget) {
      this.navTarget.classList.toggle("hidden", total <= 1)
    }

    if (this.hasDeckTarget) {
      this.deckTarget.style.paddingBottom = total > 1 ? "6px" : ""
    }

    if (total <= 1) return

    cards.forEach((card, i) => {
      const offset = (i - this.index + total) % total
      card.style.transition = animate ? "transform 0.25s ease, opacity 0.25s ease" : "none"

      if (offset === 0) {
        card.style.transform = "translateY(0) scale(1)"
        card.style.opacity = "1"
        card.style.zIndex = total
        card.style.pointerEvents = ""
      } else if (offset <= 2) {
        card.style.transform = `translateY(${offset * 6}px) scale(${1 - offset * 0.03})`
        card.style.opacity = offset === 1 ? "0.6" : "0.3"
        card.style.zIndex = total - offset
        card.style.pointerEvents = "none"
      } else {
        card.style.transform = "translateY(12px) scale(0.94)"
        card.style.opacity = "0"
        card.style.zIndex = 0
        card.style.pointerEvents = "none"
      }
    })
  }
}
