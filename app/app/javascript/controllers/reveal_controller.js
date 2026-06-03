import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  toggle(event) {
    const name = event.params.panel
    this.panelTargets.forEach((panel) => {
      if (panel.dataset.panelName === name) {
        panel.hidden = !panel.hidden
      } else {
        panel.hidden = true
      }
    })
  }
}
