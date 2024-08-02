import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal"];

  connect() {
    document.addEventListener("turbo:before-render", this.close);
  }

  disconnect() {
    document.removeEventListener("turbo:before-render", this.close);
  }

  open() {
    this.modalTarget.showModal();
  }

  close() {
    this.modalTarget.setAttribute("closing", "");

    Promise.all(
      this.modalTarget.getAnimations().map((animation) => animation.finished),
    ).then(() => {
      this.modalTarget.removeAttribute("closing");
      this.modalTarget.close();
    });
  }

  forceClose() {
    this.modalTarget.close();
  }
}
