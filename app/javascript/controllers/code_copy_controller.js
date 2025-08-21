import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="code-copy"
export default class extends Controller {
    static targets = ["button"]
    static values = { code: String }

    connect() {
        this.originalText = this.buttonTarget.textContent
    }

    copy() {
        navigator.clipboard.writeText(this.codeValue).then(() => {
            this.showSuccess()
        }).catch(() => {
            this.showError()
        })
    }

    showSuccess() {
        const originalText = this.buttonTarget.textContent
        this.buttonTarget.textContent = "Copied!"
        this.buttonTarget.classList.add("bg-green-600")

        setTimeout(() => {
            this.buttonTarget.textContent = originalText
            this.buttonTarget.classList.remove("bg-green-600")
        }, 2000)
    }

    showError() {
        const originalText = this.buttonTarget.textContent
        this.buttonTarget.textContent = "Failed"
        this.buttonTarget.classList.add("bg-red-600")

        setTimeout(() => {
            this.buttonTarget.textContent = originalText
            this.buttonTarget.classList.remove("bg-red-600")
        }, 2000)
    }
}
