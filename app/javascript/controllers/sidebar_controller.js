import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["offcanvas"]

  closeSidebar() {
    if (this.hasOffcanvasTarget) {
      const offcanvas = bootstrap.Offcanvas.getInstance(this.offcanvasTarget)
      if (offcanvas) {
        offcanvas.hide()
      }
    }
  }
}
