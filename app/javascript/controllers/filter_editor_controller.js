import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["conditionsContainer", "logicOperator", "hiddenInput", "addButton"]
  static values = { labels: Array }

  connect() {
    this.conditionIndex = this.element.querySelectorAll('.condition-row').length
    this.updateConditions()

    // Listen for turbo stream events
    document.addEventListener('turbo:before-stream-render', this.beforeStreamRender.bind(this))
  }

  disconnect() {
    document.removeEventListener('turbo:before-stream-render', this.beforeStreamRender.bind(this))
  }

  beforeStreamRender(event) {
    // Check if this stream is appending to our conditions container
    if (event.target.getAttribute('target') === 'conditions-container') {
      // We'll update after the stream renders
      setTimeout(() => {
        this.conditionIndex++
        this.updateConditions()
      }, 0)
    }
  }

  beforeAdd(event) {
    // Update the link href with the current index before the request
    const link = event.target.closest('a')
    const url = new URL(link.href)
    url.searchParams.set('index', this.conditionIndex)
    link.href = url.toString()
  }


  removeCondition(event) {
    const conditionRow = event.target.closest('.condition-row')
    conditionRow.remove()
    this.updateConditions()
  }

  updateOperators(event) {
    const select = event.target
    const index = select.dataset.index
    const field = select.value
    const operatorSelect = this.element.querySelector(`select[name="conditions[${index}][operator]"]`)
    const valueSelect = this.element.querySelector(`select[name="conditions[${index}][value]"]`)

    // Clear and update operator options
    operatorSelect.innerHTML = '<option value="">Condition</option>'
    valueSelect.innerHTML = '<option value="">Choose value...</option>'

    if (field === 'label') {
      operatorSelect.innerHTML += '<option value="has">has</option>'
      operatorSelect.innerHTML += '<option value="not_has">does not have</option>'
    }

    this.updateConditions()
  }

  updateValues(event) {
    const select = event.target
    const index = select.dataset.index
    const field = this.element.querySelector(`select[name="conditions[${index}][field]"]`).value
    const valueSelect = this.element.querySelector(`select[name="conditions[${index}][value]"]`)

    // Clear value options
    valueSelect.innerHTML = '<option value="">Choose value...</option>'

    if (field === 'label') {
      this.labelsValue.forEach(([name, _, color]) => {
        const option = document.createElement('option')
        option.value = name
        option.textContent = name
        option.dataset.color = color
        valueSelect.appendChild(option)
      })
    }

    this.updateConditions()
  }

  updateConditions() {
    const logicOperator = this.logicOperatorTarget.value
    const conditions = []

    // Collect all condition data
    this.element.querySelectorAll('.condition-row').forEach((row, index) => {
      const field = row.querySelector(`select[name*="[field]"]`)?.value
      const operator = row.querySelector(`select[name*="[operator]"]`)?.value
      const value = row.querySelector(`select[name*="[value]"]`)?.value

      if (field && operator && value) {
        conditions.push({
          type: 'condition',
          field: field,
          operator: operator,
          value: value
        })
      }
    })

    // Build the filter group
    const filterGroup = {
      type: 'group',
      operator: logicOperator,
      conditions: conditions
    }

    // Update hidden input
    this.hiddenInputTarget.value = JSON.stringify(filterGroup)
  }
}
