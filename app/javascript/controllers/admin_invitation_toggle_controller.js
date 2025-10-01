import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="admin-invitation-toggle"
export default class extends Controller {
    static targets = ["checkbox", "submitButton", "submitText"]

    connect() {
        this.updateSubmitButton()
    }

    toggle() {
        this.updateSubmitButton()
    }

    updateSubmitButton() {
        const isChecked = this.checkboxTarget.checked

        if (isChecked) {
            this.submitTextTarget.textContent = "Create Profile & Send Invitation"
        } else {
            this.submitTextTarget.textContent = "Create Profile & Generate Link"
        }
    }
}
