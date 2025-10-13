import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="work-opportunities"
export default class extends Controller {
    static targets = ["details", "chevronDown", "chevronUp", "toggleButton"]

    connect() {
        // Initialize in collapsed state
        this.isExpanded = false
    }

    toggle(event) {
        // Prevent event bubbling if clicking the button directly
        event?.stopPropagation()

        if (this.isExpanded) {
            this.collapse()
        } else {
            this.expand()
        }
    }

    expand() {
        this.isExpanded = true

        // Show details with smooth animation
        this.detailsTarget.classList.remove("hidden")

        // Animate in
        requestAnimationFrame(() => {
            this.detailsTarget.style.opacity = "0"
            this.detailsTarget.style.transform = "translateY(-10px)"

            requestAnimationFrame(() => {
                this.detailsTarget.style.transition = "opacity 300ms ease-out, transform 300ms ease-out"
                this.detailsTarget.style.opacity = "1"
                this.detailsTarget.style.transform = "translateY(0)"
            })
        })

        // Toggle chevrons
        this.chevronDownTarget.classList.add("hidden")
        this.chevronUpTarget.classList.remove("hidden")
    }

    collapse() {
        this.isExpanded = false

        // Animate out
        this.detailsTarget.style.opacity = "0"
        this.detailsTarget.style.transform = "translateY(-10px)"

        // Hide after animation completes
        setTimeout(() => {
            this.detailsTarget.classList.add("hidden")
            this.detailsTarget.style.transform = "translateY(0)"
        }, 300)

        // Toggle chevrons
        this.chevronDownTarget.classList.remove("hidden")
        this.chevronUpTarget.classList.add("hidden")
    }
}

