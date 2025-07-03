import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rule-builder"
export default class extends Controller {
  static targets = ["conditionsContainer"]
  static values = {
    initialRule: Object
  }

  connect() {
    console.log("Rule builder connected")
    this.initializeBuilder()
  }

  initializeBuilder() {
    // Initialize with existing rule if present
    const initialRule = this.initialRuleValue
    if (initialRule && Object.keys(initialRule).length > 0) {
      this.loadExistingRule(initialRule)
    }
    
    // Set up event listeners for dynamic updates
    this.element.addEventListener('change', this.updateRuleFromDOM.bind(this))
    this.element.addEventListener('input', this.updateRuleFromDOM.bind(this))
  }

  updateLogicOperator(event) {
    this.updateRuleFromDOM()
  }


  removeCondition(event) {
    const conditionGroup = event.target.closest('.condition-group')
    conditionGroup.remove()
    this.updateRuleFromDOM()
  }


  updateRuleFromDOM() {
    const logicOperator = this.element.querySelector('select').value
    const conditions = []

    // Get all condition elements
    const conditionElements = this.element.querySelectorAll('.condition-group')

    conditionElements.forEach(element => {
      const operator = element.querySelector('.condition-operator').value
      const valueSelect = element.querySelector('.condition-value')
      const value = valueSelect ? valueSelect.value : ''

      if (value && value !== '') {
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
    this.updateHiddenInput()
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

  loadExistingRule(rule) {
    // Set the logic operator
    const operator = Object.keys(rule)[0]
    if (operator) {
      const select = this.element.querySelector('select')
      if (select) select.value = operator
    }

    this.updateRule(rule)
  }
}
