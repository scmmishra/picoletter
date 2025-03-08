import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "dropdown", "addButton", "tagList"];

  connect() {
    this.selectedLabels = this.inputTarget.value
      ? this.inputTarget.value.split(", ")
      : [];
    this.dropdownVisible = false;
    document.addEventListener("click", this.closeDropdownOnClickOutside);
  }

  disconnect() {
    document.removeEventListener("click", this.closeDropdownOnClickOutside);
  }

  toggleDropdown(event) {
    event.stopPropagation();
    this.dropdownVisible = !this.dropdownVisible;

    if (this.dropdownVisible) {
      this.dropdownTarget.classList.remove("hidden");
    } else {
      this.dropdownTarget.classList.add("hidden");
    }
  }

  removeTag(event) {
    console.log(event);
  }

  toggleLabel(event) {
    console.log(event);
  }
}
