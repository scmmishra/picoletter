// app/javascript/controllers/color_picker_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["colorPicker", "hex"];

  connect() {
    // Set random color on connect
    const randomColor = "#" + Math.floor(Math.random() * 16777215).toString(16);
    this.colorPickerTarget.value = randomColor;

    // Initialize the hex display with the current color value
    this.updateHexDisplay();

    // Add event listener for color changes
    this.colorPickerTarget.addEventListener(
      "input",
      this.updateHexDisplay.bind(this),
    );
  }

  disconnect() {
    // Clean up event listener when controller disconnects
    this.colorPickerTarget.removeEventListener(
      "input",
      this.updateHexDisplay.bind(this),
    );
  }

  updateHexDisplay() {
    // Get the current color value from the input
    const colorValue = this.colorPickerTarget.value;

    // Update the hex display
    this.hexTarget.textContent = colorValue.toUpperCase();
  }
}
