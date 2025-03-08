import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dropdown", "addButton", "tagList"];

  connect() {
    this.dropdownVisible = false;
    this.closeDropdownOnClickOutside = this.closeDropdownOnClickOutside.bind(this);
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

  closeDropdownOnClickOutside(event) {
    if (this.dropdownVisible && 
        !this.addButtonTarget.contains(event.target) && 
        !this.dropdownTarget.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden");
      this.dropdownVisible = false;
    }
  }
}
