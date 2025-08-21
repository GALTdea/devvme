import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="loading"
// Provides loading states for buttons and forms
export default class extends Controller {
    static targets = ["button", "form", "overlay"]
    static values = {
        text: { type: String, default: "Loading..." },
        spinner: { type: Boolean, default: true }
    }

    connect() {
        console.log("Loading controller connected")
    }

    // Show loading state on form submission
    showFormLoading(event) {
        if (this.hasButtonTarget) {
            this.showButtonLoading()
        }

        if (this.hasOverlayTarget) {
            this.showOverlay()
        }
    }

    // Show loading state on button click
    showButtonLoading() {
        const button = this.buttonTarget
        const originalText = button.textContent

        button.disabled = true
        button.dataset.originalText = originalText

        const spinnerHtml = this.spinnerValue ? this.getSpinnerHtml() : ''
        button.innerHTML = `${spinnerHtml}${this.textValue}`

        // Add loading class for styling
        button.classList.add('loading')
    }

    // Hide loading state
    hideLoading() {
        if (this.hasButtonTarget) {
            this.hideButtonLoading()
        }

        if (this.hasOverlayTarget) {
            this.hideOverlay()
        }
    }

    hideButtonLoading() {
        const button = this.buttonTarget

        if (button.dataset.originalText) {
            button.disabled = false
            button.textContent = button.dataset.originalText
            delete button.dataset.originalText
            button.classList.remove('loading')
        }
    }

    showOverlay() {
        this.overlayTarget.classList.remove('hidden')
        this.overlayTarget.style.opacity = '0'
        this.overlayTarget.style.transition = 'opacity 0.3s ease-out'

        requestAnimationFrame(() => {
            this.overlayTarget.style.opacity = '1'
        })
    }

    hideOverlay() {
        this.overlayTarget.style.opacity = '0'
        setTimeout(() => {
            this.overlayTarget.classList.add('hidden')
        }, 300)
    }

    getSpinnerHtml() {
        return `
            <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-current inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
        `
    }

    // Reset loading state (useful for validation errors)
    reset() {
        this.hideLoading()
    }
}
