import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    addEventListener("trix-before-initialize", (event) => {
      Trix.config.blockAttributes.heading1.tagName = "h2";
    });
  }
}
