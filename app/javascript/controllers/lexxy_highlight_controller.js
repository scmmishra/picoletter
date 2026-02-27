import { Controller } from "@hotwired/stimulus"
import { highlightCode } from "lexxy"

export default class extends Controller {
  connect() {
    // ActionText content may be inserted via Turbo; run Prism highlighting on each connect.
    highlightCode()
  }
}
