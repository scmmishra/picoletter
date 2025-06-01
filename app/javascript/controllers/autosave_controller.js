import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "editor", "title"]
  static values = { 
    url: String,
    debounceDelay: { type: Number, default: 3000 }
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

      if (response.ok) {
        const data = await response.json()
        // Update the editor content with the server response to ensure consistency
        this.updateContentFromServer(data)
      } else {
        console.error("Autosave failed:", response.statusText)
      }
    } catch (error) {
      console.error("Autosave error:", error)
    } finally {
      this.pendingSave = false
    }
  }

  updateContentFromServer(data) {
    // Only update if content differs to avoid unnecessary DOM manipulation
    const currentContent = this.editorTarget.editor.getDocument().toString()
    const serverContent = data.content
    
    if (currentContent !== serverContent) {
      // Temporarily disable change listeners to prevent infinite loops
      this.editorTarget.removeEventListener("trix-change", this.handleEditorChange.bind(this))
      
      // Update the Trix editor content
      this.editorTarget.editor.loadHTML(serverContent)
      
      // Re-enable change listeners
      setTimeout(() => {
        this.editorTarget.addEventListener("trix-change", this.handleEditorChange.bind(this))
      }, 100)
    }

    // Update title if it differs
    if (this.titleTarget.value !== data.title) {
      this.titleTarget.value = data.title
    }
  }

  clearDebounceTimer() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = null
    }
  }
}
