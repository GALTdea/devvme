import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Connects to data-controller="sortable"
export default class extends Controller {
    static targets = ["item"]
    static values = {
        url: String,
        animation: { type: Number, default: 150 },
        ghostClass: { type: String, default: "sortable-ghost" },
        dragClass: { type: String, default: "sortable-drag" }
    }

    connect() {
        this.sortable = Sortable.create(this.element, {
            animation: this.animationValue,
            ghostClass: this.ghostClassValue,
            dragClass: this.dragClassValue,
            chosenClass: "sortable-chosen",
            delayOnTouchStart: true,
            delay: 100,
            touchStartThreshold: 5,
            forceFallback: true,
            fallbackClass: "sortable-fallback",
            fallbackOnBody: true,
            swapThreshold: 0.65,
            onStart: this.onStart.bind(this),
            onEnd: this.onEnd.bind(this),
            onMove: this.onMove.bind(this)
        })
    }

    disconnect() {
        if (this.sortable) {
            this.sortable.destroy()
        }
    }

    onStart(event) {
        // Add visual feedback when dragging starts
        event.item.classList.add("dragging")
        this.element.classList.add("sorting-active")

        // Add slight scale effect to other items
        this.itemTargets.forEach(item => {
            if (item !== event.item) {
                item.classList.add("sorting-inactive")
            }
        })

        // Show visual indicators
        this.showDropZones()
    }

    onMove(event) {
        // Provide visual feedback during move
        const related = event.related
        if (related) {
            related.classList.add("drop-target")
            setTimeout(() => {
                related.classList.remove("drop-target")
            }, 200)
        }
    }

    onEnd(event) {
        // Clean up visual feedback
        event.item.classList.remove("dragging")
        this.element.classList.remove("sorting-active")

        this.itemTargets.forEach(item => {
            item.classList.remove("sorting-inactive", "drop-target")
        })

        this.hideDropZones()

        // Only proceed if the order actually changed
        if (event.oldIndex !== event.newIndex) {
            this.updateOrder()
        }
    }

    showDropZones() {
        // Add visual drop zone indicators
        this.element.classList.add("show-drop-zones")
    }

    hideDropZones() {
        this.element.classList.remove("show-drop-zones")
    }

    updateOrder() {
        if (!this.hasUrlValue) {
            console.error("Sortable controller: No URL provided for reordering")
            return
        }

        // Show loading state
        this.element.classList.add("updating-order")

        // Get project IDs in new order
        const projectIds = this.itemTargets.map(item => item.dataset.projectId).filter(id => id)

        // Send AJAX request to update order
        fetch(this.urlValue, {
            method: "PATCH",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": this.getCSRFToken(),
                "Accept": "application/json"
            },
            body: JSON.stringify({
                project_ids: projectIds
            })
        })
            .then(response => response.json())
            .then(data => {
                this.element.classList.remove("updating-order")

                if (data.status === "success") {
                    this.showSuccessMessage(data.message)
                } else {
                    this.showErrorMessage(data.message || "Failed to update project order")
                    // Revert the order on error
                    this.revertOrder()
                }
            })
            .catch(error => {
                console.error("Error updating project order:", error)
                this.element.classList.remove("updating-order")
                this.showErrorMessage("An error occurred while updating project order")
                this.revertOrder()
            })
    }

    revertOrder() {
        // Force a page reload to revert to the server state
        // In a more sophisticated implementation, we could store the original order
        window.location.reload()
    }

    showSuccessMessage(message) {
        this.showMessage(message, "success")
    }

    showErrorMessage(message) {
        this.showMessage(message, "error")
    }

    showMessage(message, type) {
        // Create a temporary message element
        const messageEl = document.createElement("div")
        messageEl.className = `fixed top-4 right-4 z-50 px-4 py-2 rounded-md shadow-lg transition-all duration-300 transform translate-x-full ${type === "success"
                ? "bg-green-100 border border-green-300 text-green-800"
                : "bg-red-100 border border-red-300 text-red-800"
            }`
        messageEl.textContent = message

        document.body.appendChild(messageEl)

        // Slide in
        requestAnimationFrame(() => {
            messageEl.classList.remove("translate-x-full")
        })

        // Remove after 3 seconds
        setTimeout(() => {
            messageEl.classList.add("translate-x-full")
            setTimeout(() => {
                if (messageEl.parentNode) {
                    messageEl.parentNode.removeChild(messageEl)
                }
            }, 300)
        }, 3000)
    }

    getCSRFToken() {
        const token = document.querySelector('meta[name="csrf-token"]')
        return token ? token.content : ""
    }
}
