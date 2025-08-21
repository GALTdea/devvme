import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["modal", "title", "message", "confirmButton"]
    static values = {
        title: String,
        message: String,
        confirmText: String,
        confirmClass: String,
        action: String,
        method: String
    }

    connect() {
        // Set up default values
        this.confirmAction = null
    }

    // Show confirmation modal
    show(event) {
        event.preventDefault()

        // Store the action to perform on confirmation
        this.confirmAction = () => {
            if (this.actionValue && this.methodValue) {
                this.performAction()
            } else {
                // Default behavior - follow the link
                window.location.href = event.target.href || event.target.closest('a').href
            }
        }

        // Update modal content
        if (this.hasTitleTarget) {
            this.titleTarget.textContent = this.titleValue || "Confirm Action"
        }

        if (this.hasMessageTarget) {
            this.messageTarget.textContent = this.messageValue || "Are you sure you want to proceed?"
        }

        if (this.hasConfirmButtonTarget) {
            this.confirmButtonTarget.textContent = this.confirmTextValue || "Confirm"

            // Update button styling
            if (this.confirmClassValue) {
                this.confirmButtonTarget.className = this.confirmClassValue
            }
        }

        // Show modal
        this.modalTarget.classList.remove('hidden')
        this.modalTarget.classList.add('flex')

        // Focus confirm button
        if (this.hasConfirmButtonTarget) {
            this.confirmButtonTarget.focus()
        }
    }

    // Hide confirmation modal
    hide() {
        this.modalTarget.classList.add('hidden')
        this.modalTarget.classList.remove('flex')
        this.confirmAction = null
    }

    // Confirm the action
    confirm() {
        if (this.confirmAction) {
            this.confirmAction()
        }
        this.hide()
    }

    // Cancel the action
    cancel() {
        this.hide()
    }

    // Handle backdrop click
    backdropClick(event) {
        if (event.target === this.modalTarget) {
            this.cancel()
        }
    }

    // Handle keyboard events
    keydown(event) {
        if (event.key === 'Escape') {
            this.cancel()
        } else if (event.key === 'Enter') {
            this.confirm()
        }
    }

    // Perform the specified action
    performAction() {
        const form = document.createElement('form')
        form.method = 'POST'
        form.action = this.actionValue

        // Add method override for non-POST methods
        if (this.methodValue.toUpperCase() !== 'POST') {
            const methodField = document.createElement('input')
            methodField.type = 'hidden'
            methodField.name = '_method'
            methodField.value = this.methodValue.toUpperCase()
            form.appendChild(methodField)
        }

        // Add CSRF token
        const csrfToken = document.querySelector('meta[name="csrf-token"]')
        if (csrfToken) {
            const csrfField = document.createElement('input')
            csrfField.type = 'hidden'
            csrfField.name = 'authenticity_token'
            csrfField.value = csrfToken.content
            form.appendChild(csrfField)
        }

        // Submit form
        document.body.appendChild(form)
        form.submit()
    }
}
