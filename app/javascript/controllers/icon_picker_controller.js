import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["currentSelection", "picker", "iconInput", "colorInput", "iconGrid"]
  static values = { currentIcon: String, currentColor: String }

  connect() {
    this.updateCurrentSelection()
    this.updateIconButtons()
    this.updateIconGridColor()
  }

  togglePicker() {
    this.pickerTarget.classList.toggle("hidden")
  }

  selectColor(event) {
    const color = event.currentTarget.dataset.color
    this.currentColorValue = color
    this.colorInputTarget.value = color
    this.updateCurrentSelection()
    this.updateColorButtons()
    this.updateIconGridColor()
  }

  selectIcon(event) {
    const icon = event.currentTarget.dataset.icon
    this.currentIconValue = icon
    this.iconInputTarget.value = icon
    this.updateCurrentSelection()
    this.updateIconButtons()
  }

  updateCurrentSelection() {
    const svg = this.currentSelectionTarget.querySelector('svg')
    const use = svg.querySelector('use')

    // Update icon
    use.setAttribute('href', `#${this.currentIconValue}`)

    // Update colors using theme data
    const selectedColorButton = this.pickerTarget.querySelector(`[data-color="${this.currentColorValue}"]`)
    if (selectedColorButton) {
      const tint = selectedColorButton.dataset.tint
      // Set background to tint color
      this.currentSelectionTarget.style.backgroundColor = tint
      // Set icon color to primary
      svg.style.color = this.currentColorValue
    }
  }

  updateColorButtons() {
    const colorButtons = this.pickerTarget.querySelectorAll('[data-color]')
    colorButtons.forEach(button => {
      if (button.dataset.color === this.currentColorValue) {
        button.classList.add('ring-2', 'ring-offset-2', 'ring-stone-400')
      } else {
        button.classList.remove('ring-2', 'ring-offset-2', 'ring-stone-400')
      }
    })
  }

  updateIconButtons() {
    const iconButtons = this.pickerTarget.querySelectorAll('[data-icon]')
    iconButtons.forEach(button => {
      // Update selection state
      if (button.dataset.icon === this.currentIconValue) {
        button.classList.add('bg-stone-100', 'border-stone-400')
      } else {
        button.classList.remove('bg-stone-100', 'border-stone-400')
      }
    })
  }

  updateIconGridColor() {
    const buttons = this.iconGridTarget.querySelectorAll('button[data-icon]')
    const selectedColorButton = this.pickerTarget.querySelector(`[data-color="${this.currentColorValue}"]`)

    if (selectedColorButton) {
      const tint = selectedColorButton.dataset.tint

      buttons.forEach(button => {
        const svg = button.querySelector('svg')
        // Set background color to tint
        button.style.backgroundColor = tint
        // Set icon color to primary
        svg.style.color = this.currentColorValue
      })
    }
  }

  // Close picker when clicking outside
  disconnect() {
    document.removeEventListener('click', this.closeOnOutsideClick)
  }

  closeOnOutsideClick = (event) => {
    if (!this.element.contains(event.target)) {
      this.pickerTarget.classList.add("hidden")
    }
  }

  pickerTargetConnected() {
    document.addEventListener('click', this.closeOnOutsideClick)
  }
}
