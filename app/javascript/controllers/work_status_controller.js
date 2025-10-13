import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="work-status"
export default class extends Controller {
    static targets = ["toggle", "preferences"]

    connect() {
        // Initialize visibility based on toggle state
        this.updatePreferencesVisibility()
    }

    togglePreferences() {
        this.updatePreferencesVisibility()
    }

    updatePreferencesVisibility() {
        const isChecked = this.toggleTarget.checked

        if (isChecked) {
            this.preferencesTarget.classList.remove("hidden")
            // Add a smooth fade-in effect
            this.preferencesTarget.style.opacity = "0"
            setTimeout(() => {
                this.preferencesTarget.style.opacity = "1"
            }, 10)
        } else {
            this.preferencesTarget.classList.add("hidden")
        }
    }
}

