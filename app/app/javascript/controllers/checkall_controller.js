import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["all", "item"]

  toggle() {
    this.itemTargets.forEach((box) => { box.checked = this.allTarget.checked })
  }
}
