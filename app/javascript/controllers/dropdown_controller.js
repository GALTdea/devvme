import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu"]
  static values = {
    placement: { type: String, default: "bottom" }
  }

  connect() {
    // Close dropdown when clicking outside
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.boundHandleClickOutside)
    
    // Close dropdown on escape key
    this.boundHandleEscape = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundHandleEscape)
    
    // Close dropdown when clicking on links inside (for better UX)
    this.menuTarget.addEventListener("click", (event) => {
      if (event.target.closest("a, button")) {
        // Small delay to allow navigation to start
        setTimeout(() => this.hide(), 100)
      }
    })
  }

  disconnect() {
    document.removeEventListener("click", this.boundHandleClickOutside)
    document.removeEventListener("keydown", this.boundHandleEscape)
    this.hide()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.isVisible()) {
      this.hide()
    } else {
      this.show()
    }
  }

  show() {
    this.menuTarget.classList.remove("hidden")
    // Add positioning classes if needed
    this.updatePosition()
  }

  hide() {
    this.menuTarget.classList.add("hidden")
  }

  isVisible() {
    return !this.menuTarget.classList.contains("hidden")
  }

  handleClickOutside(event) {
    if (this.isVisible() && !this.element.contains(event.target)) {
      this.hide()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape" && this.isVisible()) {
      this.hide()
    }
  }

  updatePosition() {
    // Flowbite-style positioning logic can be added here if needed
    // For now, CSS handles the positioning
  }
}

