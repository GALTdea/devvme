import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notification"
// Provides toast-style notifications
export default class extends Controller {
    static targets = ["container"]
    static values = {
        timeout: { type: Number, default: 5000 },
        position: { type: String, default: "top-right" }
    }

    connect() {
        console.log("Notification controller connected")
        this.setupContainer()
    }

    setupContainer() {
        if (!this.hasContainerTarget) {
            // Create notification container if it doesn't exist
            const container = document.createElement('div')
            container.className = this.getContainerClasses()
            container.setAttribute('data-notification-target', 'container')
            document.body.appendChild(container)
        }
    }

    getContainerClasses() {
        const baseClasses = 'fixed z-50 space-y-3'
        const positionClasses = {
            'top-right': 'top-4 right-4',
            'top-left': 'top-4 left-4',
            'bottom-right': 'bottom-4 right-4',
            'bottom-left': 'bottom-4 left-4',
            'top-center': 'top-4 left-1/2 transform -translate-x-1/2',
            'bottom-center': 'bottom-4 left-1/2 transform -translate-x-1/2'
        }

        return `${baseClasses} ${positionClasses[this.positionValue] || positionClasses['top-right']}`
    }

    // Show success notification
    showSuccess(event) {
        const message = event.detail?.message || event.target.dataset.message || "Success!"
        this.show(message, 'success')
    }

    // Show error notification
    showError(event) {
        const message = event.detail?.message || event.target.dataset.message || "An error occurred"
        this.show(message, 'error')
    }

    // Show info notification
    showInfo(event) {
        const message = event.detail?.message || event.target.dataset.message || "Information"
        this.show(message, 'info')
    }

    // Show warning notification
    showWarning(event) {
        const message = event.detail?.message || event.target.dataset.message || "Warning"
        this.show(message, 'warning')
    }

    // Generic show method
    show(message, type = 'info') {
        const notification = this.createNotification(message, type)
        const container = this.hasContainerTarget ? this.containerTarget : document.querySelector('[data-notification-target="container"]')

        if (container) {
            container.appendChild(notification)
            this.animateIn(notification)

            // Auto-remove after timeout
            setTimeout(() => {
                this.remove(notification)
            }, this.timeoutValue)
        }
    }

    createNotification(message, type) {
        const notification = document.createElement('div')
        notification.className = this.getNotificationClasses(type)

        const icon = this.getIcon(type)

        notification.innerHTML = `
            <div class="flex items-start">
                <div class="flex-shrink-0">
                    ${icon}
                </div>
                <div class="ml-3 w-0 flex-1">
                    <p class="text-sm font-medium">${message}</p>
                </div>
                <div class="ml-4 flex-shrink-0 flex">
                    <button type="button" class="inline-flex text-current hover:opacity-75 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-current rounded-md p-1" data-action="click->notification#dismiss">
                        <span class="sr-only">Close</span>
                        <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                        </svg>
                    </button>
                </div>
            </div>
        `

        return notification
    }

    getNotificationClasses(type) {
        const baseClasses = 'max-w-sm w-full shadow-lg rounded-lg p-4 transition-all duration-300 transform'
        const typeClasses = {
            success: 'bg-green-100 border border-green-300 text-green-800',
            error: 'bg-red-100 border border-red-300 text-red-800',
            warning: 'bg-yellow-100 border border-yellow-300 text-yellow-800',
            info: 'bg-blue-100 border border-blue-300 text-blue-800'
        }

        return `${baseClasses} ${typeClasses[type] || typeClasses.info}`
    }

    getIcon(type) {
        const icons = {
            success: `<svg class="h-6 w-6 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>`,
            error: `<svg class="h-6 w-6 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.732 15.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>`,
            warning: `<svg class="h-6 w-6 text-yellow-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.732 15.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>`,
            info: `<svg class="h-6 w-6 text-blue-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>`
        }

        return icons[type] || icons.info
    }

    animateIn(notification) {
        notification.style.opacity = '0'
        notification.style.transform = 'translateX(100%)'

        requestAnimationFrame(() => {
            notification.style.opacity = '1'
            notification.style.transform = 'translateX(0)'
        })
    }

    dismiss(event) {
        const notification = event.target.closest('[class*="bg-"]')
        if (notification) {
            this.remove(notification)
        }
    }

    remove(notification) {
        notification.style.opacity = '0'
        notification.style.transform = 'translateX(100%)'

        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification)
            }
        }, 300)
    }

    // Clear all notifications
    clearAll() {
        const container = this.hasContainerTarget ? this.containerTarget : document.querySelector('[data-notification-target="container"]')
        if (container) {
            const notifications = container.querySelectorAll('[class*="bg-"]')
            notifications.forEach(notification => this.remove(notification))
        }
    }
}
