import { Turbo } from "@hotwired/turbo-rails"

Turbo.config.forms.confirm = (message, element, submitter) => {
  const dialog = document.getElementById("turbo-confirm-dialog")
  if (!dialog) return Promise.resolve(confirm(message))

  const messageEl = document.getElementById("turbo-confirm-message")
  const buttonEl = document.getElementById("turbo-confirm-button")
  const textContainer = document.getElementById("turbo-confirm-text-container")
  const textLabel = document.getElementById("turbo-confirm-text-label")
  const textInput = document.getElementById("turbo-confirm-text-input")

  // Check submitter first (button), then fall back to element (form)
  const attr = (name) =>
    submitter?.getAttribute(name) || element?.getAttribute(name)

  messageEl.textContent = message

  // Allow custom confirm button text via data-turbo-confirm-button
  const customButton = attr("data-turbo-confirm-button")
  buttonEl.textContent = customButton || "Confirm"

  // Optional confirmation text the user must type to enable the button
  const confirmationText = attr("data-turbo-confirm-text")

  if (confirmationText) {
    textContainer.classList.remove("hidden")
    textLabel.textContent = `Please type "${confirmationText}" to confirm this action`
    textInput.value = ""
    buttonEl.disabled = true

    const onInput = () => {
      buttonEl.disabled = textInput.value !== confirmationText
    }
    textInput.addEventListener("input", onInput)

    dialog.addEventListener("close", () => {
      textInput.removeEventListener("input", onInput)
      textContainer.classList.add("hidden")
      textInput.value = ""
      buttonEl.disabled = false
    }, { once: true })
  } else {
    textContainer.classList.add("hidden")
    buttonEl.disabled = false
  }

  dialog.showModal()

  return new Promise((resolve) => {
    dialog.addEventListener("close", () => {
      resolve(dialog.returnValue === "confirm")
    }, { once: true })
  })
}
