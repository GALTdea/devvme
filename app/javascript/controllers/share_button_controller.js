import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="share-button"
export default class extends Controller {
    static values = {
        url: String,
        title: String,
        text: String
    }

    connect() {
        // Hide the button if Web Share API is not supported
        if (!navigator.share) {
            this.element.style.display = 'none'
        }
    }

    async share() {
        if (!navigator.share) {
            // Fallback: copy URL to clipboard
            try {
                await navigator.clipboard.writeText(this.urlValue)
                this.showToast('Link copied to clipboard!')
            } catch (err) {
                console.error('Failed to copy link:', err)
                this.showToast('Failed to copy link', 'error')
            }
            return
        }

        try {
            await navigator.share({
                title: this.titleValue,
                text: this.textValue,
                url: this.urlValue
            })
        } catch (err) {
            if (err.name !== 'AbortError') {
                console.error('Error sharing:', err)
                // Fallback to clipboard
                try {
                    await navigator.clipboard.writeText(this.urlValue)
                    this.showToast('Link copied to clipboard!')
                } catch (clipboardErr) {
                    console.error('Failed to copy link:', clipboardErr)
                    this.showToast('Failed to share', 'error')
                }
            }
        }
    }

    showToast(message, type = 'success') {
        // Create a simple toast notification
        const toast = document.createElement('div')
        toast.className = `fixed bottom-4 right-4 px-4 py-2 rounded-lg text-white text-sm font-medium z-50 transition-opacity duration-300 ${type === 'error' ? 'bg-red-500' : 'bg-green-500'
            }`
        toast.textContent = message

        document.body.appendChild(toast)

        // Auto-remove after 3 seconds
        setTimeout(() => {
            toast.style.opacity = '0'
            setTimeout(() => {
                document.body.removeChild(toast)
            }, 300)
        }, 3000)
    }
}
