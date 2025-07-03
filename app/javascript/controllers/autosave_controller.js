import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "editor", "title", "cohort", "spinner"]
  static values = {
    url: String,
    debounceDelay: { type: Number, default: 2000 }
  }

  connect() {
    this.debounceTimer = null
    this.pendingSave = false
    this.setupEventListeners()
  }

  disconnect() {
    this.clearDebounceTimer()
  }

  setupEventListeners() {
    // Listen for Trix editor changes
    this.editorTarget.addEventListener("trix-change", this.handleEditorChange.bind(this))
    this.editorTarget.addEventListener("trix-blur", this.handleEditorBlur.bind(this))

    // Listen for title changes
    this.titleTarget.addEventListener("input", this.handleTitleChange.bind(this))
    this.titleTarget.addEventListener("blur", this.handleTitleBlur.bind(this))

    // Listen for cohort changes
    if (this.hasCohortTarget) {
      this.cohortTarget.addEventListener("change", this.handleCohortChange.bind(this))
    }
  }

  handleEditorChange() {
    this.scheduleAutosave()
  }

  handleTitleChange() {
    this.scheduleAutosave()
  }

  handleEditorBlur() {
    this.immediateAutosave()
  }

  handleTitleBlur() {
    this.immediateAutosave()
  }

  handleCohortChange() {
    this.immediateAutosave()
  }

  scheduleAutosave() {
    this.clearDebounceTimer()
    this.debounceTimer = setTimeout(() => {
      this.performAutosave()
    }, this.debounceDelayValue)
  }

  immediateAutosave() {
    this.clearDebounceTimer()
    this.performAutosave()
  }

  async performAutosave() {
    if (this.pendingSave) return

    this.pendingSave = true
    this.showSpinner()

    try {
      const formData = new FormData(this.formTarget)

      const response = await fetch(this.urlValue, {
        method: "PATCH",
        body: formData,
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })

      if (!response.ok) {
        console.error("Autosave failed:", response.statusText)
      }
    } catch (error) {
      console.error("Autosave error:", error)
    } finally {
      this.pendingSave = false
      this.hideSpinner()
    }
  }

  clearDebounceTimer() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = null
    }
  }

  showSpinner() {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.style.display = "block"
    }
  }

  hideSpinner() {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.style.display = "none"
    }
  }
}
