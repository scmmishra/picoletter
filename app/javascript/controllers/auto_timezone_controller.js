import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.element.value = this.getCurrentTimezoneFromBrowser();
  }

  getCurrentTimezoneFromBrowser() {
    return new Date().getTimezoneOffset() / -60;
  }
}
