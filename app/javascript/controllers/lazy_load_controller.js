import { Controller } from "@hotwired/stimulus"

// Lazy loading controller using Intersection Observer
// Connects to data-controller="lazy-load"
export default class extends Controller {
    static targets = ["image"]
    static values = {
        src: String,
        rootMargin: { type: String, default: "100px" },
        threshold: { type: Number, default: 0.1 }
    }

    connect() {
        this.setupObserver()
        this.observeImages()
    }

    disconnect() {
        if (this.observer) {
            this.observer.disconnect()
        }
    }

    setupObserver() {
        // Check if Intersection Observer is supported
        if (!window.IntersectionObserver) {
            // Fallback: load all images immediately
            this.loadAllImages()
            return
        }

        this.observer = new IntersectionObserver(
            (entries) => this.handleIntersection(entries),
            {
                rootMargin: this.rootMarginValue,
                threshold: this.thresholdValue
            }
        )
    }

    observeImages() {
        this.imageTargets.forEach(image => {
            // Only observe images that aren't already loaded
            if (!image.dataset.loaded) {
                this.observer.observe(image)
            }
        })
    }

    handleIntersection(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                this.loadImage(entry.target)
                this.observer.unobserve(entry.target)
            }
        })
    }

    loadImage(img) {
        // Skip if already loaded
        if (img.dataset.loaded === "true") return

        const src = img.dataset.src || img.dataset.lazySrc
        const srcset = img.dataset.srcset || img.dataset.lazySrcset

        if (src) {
            // Add loading state
            img.style.opacity = "0"
            img.style.transition = "opacity 0.3s ease-in-out"

            // Handle load success
            img.onload = () => {
                img.style.opacity = "1"
                img.dataset.loaded = "true"
                img.classList.add("loaded")

                // Dispatch custom event
                this.dispatch("loaded", {
                    detail: { element: img, src: src }
                })
            }

            // Handle load error
            img.onerror = () => {
                img.style.opacity = "1"
                img.classList.add("error")
                console.warn(`Failed to load image: ${src}`)

                // Dispatch error event
                this.dispatch("error", {
                    detail: { element: img, src: src }
                })
            }

            // Set the source to trigger loading
            if (srcset) {
                img.srcset = srcset
            }
            img.src = src
        }
    }

    loadAllImages() {
        // Fallback method for browsers without Intersection Observer
        this.imageTargets.forEach(image => {
            this.loadImage(image)
        })
    }

    // Action to manually trigger loading
    load(event) {
        const img = event.currentTarget
        this.loadImage(img)
    }

    // Action to refresh observer (useful when new images are added)
    refresh() {
        this.observeImages()
    }
}
