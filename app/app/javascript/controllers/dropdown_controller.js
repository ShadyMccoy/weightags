import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.close = this.close.bind(this)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.hidden = !this.menuTarget.hidden
    if (!this.menuTarget.hidden) {
      document.addEventListener("click", this.close)
    }
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.hidden = true
      document.removeEventListener("click", this.close)
    }
  }

  disconnect() {
    document.removeEventListener("click", this.close)
  }
}
