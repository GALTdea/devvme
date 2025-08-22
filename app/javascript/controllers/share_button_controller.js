import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="share-button"
export default class extends Controller {
    static values = {
        url: String,
        title: String
    }

    async share(event) {
        event.preventDefault()

        const url = this.urlValue
        const title = this.titleValue

        // Check if Web Share API is supported
        if (navigator.share) {
            try {
                await navigator.share({
                    title: title,
                    url: url
                })
            } catch (error) {
                console.log('Error sharing:', error)
                this.fallbackShare(url)
            }
        } else {
            this.fallbackShare(url)
        }
    }

    fallbackShare(url) {
        // Copy to clipboard as fallback
        navigator.clipboard.writeText(url).then(() => {
            this.showNotification('Profile URL copied to clipboard!')
        }).catch((err) => {
            console.error('Could not copy text: ', err)
            this.showNotification('Failed to copy URL', 'error')
        })
    }

    showNotification(message, type = 'success') {
        const notification = document.createElement('div')
        const bgColor = type === 'error' ? 'bg-red-500' : 'bg-green-500'
        notification.className = `fixed top-4 right-4 ${bgColor} text-white px-4 py-2 rounded-md shadow-lg z-50 transition-opacity duration-300`
        notification.textContent = message

        document.body.appendChild(notification)

        // Remove notification after 3 seconds
        setTimeout(() => {
            notification.style.opacity = '0'
            setTimeout(() => {
                if (document.body.contains(notification)) {
                    document.body.removeChild(notification)
                }
            }, 300)
        }, 3000)
    }
}