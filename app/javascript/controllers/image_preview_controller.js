import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="image-preview"
export default class extends Controller {
    static targets = ["input", "preview"]

    connect() {
        // Initialize preview if there's already an image
        this.showCurrentImage()
    }

    preview() {
        const input = this.inputTarget
        const preview = this.previewTarget
        const file = input.files[0]

        if (file) {
            const reader = new FileReader()

            reader.onload = (e) => {
                preview.src = e.target.result
                preview.classList.remove("hidden")

                // Hide the placeholder if it exists
                const placeholder = preview.nextElementSibling
                if (placeholder && placeholder.classList.contains("placeholder")) {
                    placeholder.classList.add("hidden")
                }
            }

            reader.readAsDataURL(file)
        } else {
            this.showCurrentImage()
        }
    }

    showCurrentImage() {
        const preview = this.previewTarget
        const currentImageUrl = preview.dataset.currentImage

        if (currentImageUrl && currentImageUrl !== "") {
            preview.src = currentImageUrl
            preview.classList.remove("hidden")

            // Hide the placeholder if it exists
            const placeholder = preview.nextElementSibling
            if (placeholder && placeholder.classList.contains("placeholder")) {
                placeholder.classList.add("hidden")
            }
        } else {
            preview.classList.add("hidden")

            // Show the placeholder if it exists
            const placeholder = preview.nextElementSibling
            if (placeholder && placeholder.classList.contains("placeholder")) {
                placeholder.classList.remove("hidden")
            }
        }
    }
}
