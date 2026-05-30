import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="resume-bullets-copy"
export default class extends Controller {
    static targets = ["button", "bulletText"]
    static values = { allText: String }

    copyBullet(event) {
        const index = event.params.index
        const text = this.bulletTextTargets[index]?.textContent?.trim()
        if (!text) return

        this.writeClipboard(text, event.currentTarget)
    }

    copyAll() {
        const text = this.allTextValue || this.bulletTextTargets.map((el) => el.textContent.trim()).filter(Boolean).join("\n")
        if (!text) return

        this.writeClipboard(text, this.hasButtonTarget ? this.buttonTarget : null)
    }

    writeClipboard(text, button) {
        navigator.clipboard.writeText(text).then(() => {
            if (button) this.flashButton(button, "Copied!", "bg-green-600")
        }).catch(() => {
            if (button) this.flashButton(button, "Failed", "bg-red-600")
        })
    }

    flashButton(button, message, colorClass) {
        const originalText = button.textContent
        button.textContent = message
        button.classList.add(colorClass)

        setTimeout(() => {
            button.textContent = originalText
            button.classList.remove(colorClass)
        }, 2000)
    }
}
