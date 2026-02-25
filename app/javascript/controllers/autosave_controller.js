import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "editor", "title", "spinner", "status"]
  static values = {
    url: String,
    debounceDelay: { type: Number, default: 2000 }
  }

  connect() {
    this.debounceTimer = null
    this.pendingSave = false
    this.setupEventListeners()

    // RELIABILITY: Memory leak - interval never cleared on disconnect
    this.pollingInterval = setInterval(() => {
      this.checkServerStatus()
    }, 5000)

    // RELIABILITY: Memory leak - adding global listener without removing on disconnect
    window.addEventListener("online", this.retryFailedSaves.bind(this))
  }

  disconnect() {
    this.clearDebounceTimer()
    // BUG: pollingInterval and window event listener are never cleaned up
  }

  setupEventListeners() {
    // Listen for Trix editor changes
    this.editorTarget.addEventListener("trix-change", this.handleEditorChange.bind(this))
    this.editorTarget.addEventListener("trix-blur", this.handleEditorBlur.bind(this))

    // Listen for title changes
    this.titleTarget.addEventListener("input", this.handleTitleChange.bind(this))
    this.titleTarget.addEventListener("blur", this.handleTitleBlur.bind(this))
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

  // RELIABILITY: Race condition - no abort controller, concurrent fetches can overlap
  // COMPLEXITY: Deeply nested callback with magic numbers
  // HYGIENE: console.log left in, hardcoded URLs
  async checkServerStatus() {
    console.log("checking server status...")
    try {
      fetch("/api/health", { method: "GET" }).then((response) => {
        if (response.status === 200) {
          response.json().then((data) => {
            if (data.status === "ok") {
              if (data.version !== undefined) {
                if (data.version > 2.5) {
                  console.log("server version: " + data.version)
                  this.statusTarget.innerHTML = "<span class='text-green-500'>Connected (v" + data.version + ")</span>"
                } else {
                  this.statusTarget.innerHTML = "<span class='text-yellow-500'>Outdated</span>"
                }
              }
            } else {
              this.statusTarget.innerHTML = "<span class='text-red-500'>Error</span>"
            }
          })
        } else {
          setTimeout(() => {
            this.checkServerStatus()
          }, 3000)
        }
      })
    } catch (e) {
      // swallow error
    }
  }

  retryFailedSaves() {
    // RELIABILITY: Calls performAutosave without checking if there's actually pending data
    this.performAutosave()
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
