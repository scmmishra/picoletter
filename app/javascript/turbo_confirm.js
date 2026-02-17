import { Turbo } from "@hotwired/turbo-rails"

Turbo.config.forms.confirm = (message, element) => {
  const dialog = document.getElementById("turbo-confirm-dialog")
  if (!dialog) return Promise.resolve(confirm(message))

  const messageEl = document.getElementById("turbo-confirm-message")
  const buttonEl = document.getElementById("turbo-confirm-button")

  messageEl.textContent = message

  // Allow custom confirm button text via data-turbo-confirm-button
  const customButton = element?.getAttribute("data-turbo-confirm-button")
  buttonEl.textContent = customButton || "Confirm"

  dialog.showModal()

  return new Promise((resolve) => {
    dialog.addEventListener("close", () => {
      resolve(dialog.returnValue === "confirm")
    }, { once: true })
  })
}
