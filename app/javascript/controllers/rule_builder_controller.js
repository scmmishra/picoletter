import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rule-builder"
export default class extends Controller {
  static targets = ["container", "output", "preview"]
  static values = {
    labels: Array,
    initialRule: Object
  }

  connect() {
    console.log("Rule builder connected with labels:", this.labelsValue)
    this.initializeBuilder()
  }

  initializeBuilder() {
    // Create the main structure
    this.containerTarget.innerHTML = this.buildRuleInterface()

    // Add event listeners
    this.addEventListeners()

    // Initialize with existing rule or add first condition
    const initialRule = this.initialRuleValue
    if (initialRule && Object.keys(initialRule).length > 0) {
      this.loadExistingRule(initialRule)
    } else {
      // Add one condition by default
      this.addCondition()
    }
  }

  buildRuleInterface() {
    return `
      <div class="space-y-4">
        <!-- Logic Type -->
        <div class="flex items-center gap-3">
          <span class="text-sm text-stone-600">Subscribers must match:</span>
          <select data-action="change->rule-builder#updateLogicOperator" class="px-3 py-2 border border-stone-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
            <option value="and">All conditions</option>
            <option value="or">Any condition</option>
          </select>
        </div>

        <!-- Conditions -->
        <div class="space-y-3" data-rule-builder-target="conditionsContainer">
          <!-- Dynamic conditions will be added here -->
        </div>

        <!-- Add Condition Button -->
        <button type="button"
                data-action="click->rule-builder#addCondition"
                class="inline-flex items-center px-4 py-2 text-sm font-medium text-blue-600 bg-blue-50 hover:bg-blue-100 rounded-md border border-blue-200 transition-colors">
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
          </svg>
          Add Condition
        </button>

        <!-- JSON Preview -->
        <div class="mt-6 border-t pt-4">
          <details class="group">
            <summary class="flex items-center cursor-pointer text-sm font-medium text-stone-600 hover:text-stone-800">
              <svg class="w-4 h-4 mr-2 transform group-open:rotate-90 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
              </svg>
              JSONLogic Rule Preview
            </summary>
            <div class="mt-3 p-3 bg-stone-50 rounded-md border">
              <pre class="text-xs text-stone-600 font-mono whitespace-pre-wrap" data-rule-builder-target="preview">No conditions yet</pre>
            </div>
          </details>
        </div>
      </div>
    `
  }

  addEventListeners() {
    // Event delegation for dynamic elements
    this.element.addEventListener('change', this.handleChange.bind(this))
    this.element.addEventListener('click', this.handleClick.bind(this))
  }

  handleChange(event) {
    if (event.target.matches('[data-condition-field]')) {
      this.updateRuleFromDOM()
    }
  }

  handleClick(event) {
    if (event.target.matches('[data-remove-condition]')) {
      event.preventDefault()
      this.removeCondition(event.target)
    }
  }

  updateLogicOperator(event) {
    const operator = event.target.value
    this.currentRule = { [operator]: this.currentRule[Object.keys(this.currentRule)[0]] }
    this.updateRuleFromDOM()
  }

  addCondition() {
    const conditionsContainer = this.element.querySelector('[data-rule-builder-target="conditionsContainer"]')
    const conditionId = `condition_${Date.now()}`

    const conditionHTML = `
      <div class="flex items-center gap-3 p-4 border border-stone-200 rounded-lg bg-white" data-condition-id="${conditionId}">
        <select data-condition-field="operator" class="px-3 py-2 border border-stone-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
          <option value="in">Has label</option>
          <option value="!in">Does not have label</option>
        </select>

        <select data-condition-field="value" class="px-3 py-2 border border-stone-300 rounded-md text-sm flex-1 focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
          <option value="">Choose a label...</option>
          ${this.labelsValue.map(label =>
            `<option value="${label.name}">${label.name}</option>`
          ).join('')}
        </select>

        <button type="button"
                data-remove-condition
                class="text-stone-400 hover:text-red-500 p-2 hover:bg-red-50 rounded-md transition-colors">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>
    `

    conditionsContainer.insertAdjacentHTML('beforeend', conditionHTML)
    this.updateRuleFromDOM()
  }

  removeCondition(button) {
    const conditionElement = button.closest('[data-condition-id]')
    if (conditionElement) {
      conditionElement.remove()
      this.updateRuleFromDOM()
    }
  }

  updateRuleFromDOM() {
    const logicOperator = this.element.querySelector('select').value
    const conditions = []

    // Get all condition elements
    const conditionElements = this.element.querySelectorAll('[data-condition-id]')

    conditionElements.forEach(element => {
      const operator = element.querySelector('[data-condition-field="operator"]').value
      const value = element.querySelector('[data-condition-field="value"]').value

      if (value) {
        if (operator === 'in') {
          conditions.push({
            "in": [value, {"var": "labels"}]
          })
        } else if (operator === '!in') {
          conditions.push({
            "!": {"in": [value, {"var": "labels"}]}
          })
        }
      }
    })

    // Build the rule
    const rule = conditions.length > 0 ? { [logicOperator]: conditions } : {}
    this.updateRule(rule)
  }

  updateRule(rule) {
    this.currentRule = rule

    // Update the hidden input
    this.updateHiddenInput()

    // Update the preview
    this.updatePreview()
  }

  updateHiddenInput() {
    // Find or create the hidden input for filter_conditions
    let hiddenInput = this.element.querySelector('input[name="cohort[filter_conditions]"]')
    if (!hiddenInput) {
      hiddenInput = document.createElement('input')
      hiddenInput.type = 'hidden'
      hiddenInput.name = 'cohort[filter_conditions]'
      this.element.appendChild(hiddenInput)
    }

    hiddenInput.value = JSON.stringify(this.currentRule)
  }

  updatePreview() {
    if (this.hasPreviewTarget) {
      this.previewTarget.textContent = JSON.stringify(this.currentRule, null, 2)
    }
  }

  loadExistingRule(rule) {
    // Set the logic operator
    const operator = Object.keys(rule)[0]
    if (operator) {
      const select = this.element.querySelector('select')
      if (select) select.value = operator

      // Load conditions
      const conditions = rule[operator] || []
      conditions.forEach(condition => {
        this.addConditionFromRule(condition)
      })
    }

    this.updateRule(rule)
  }

  addConditionFromRule(condition) {
    this.addCondition()

    // Find the last added condition and populate it
    const conditionElements = this.element.querySelectorAll('[data-condition-id]')
    const lastCondition = conditionElements[conditionElements.length - 1]

    if (condition.in) {
      lastCondition.querySelector('[data-condition-field="operator"]').value = 'in'
      lastCondition.querySelector('[data-condition-field="value"]').value = condition.in[0]
    } else if (condition['!'] && condition['!'].in) {
      lastCondition.querySelector('[data-condition-field="operator"]').value = '!in'
      lastCondition.querySelector('[data-condition-field="value"]').value = condition['!'].in[0]
    }
  }
}
