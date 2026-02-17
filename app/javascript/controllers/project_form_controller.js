import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="project-form"
export default class extends Controller {
    static targets = ["thumbnailDropzone", "thumbnailPreview", "thumbnailImage", "thumbnailUploadArea",
        "imagesDropzone", "imagesPreview", "imagesGrid", "form", "submitButton"]
    static values = {
        maxImages: { type: Number, default: 5 },
        maxImageSize: { type: Number, default: 5242880 } // 5MB
    }

    connect() {
        console.log("Project form controller connected")
        this.debugEnabled = this.isDebugEnabled()
        this.setupFormSubmission()
        this.initializeAnimations()
        this.setupDebugListeners()
    }

    setupFormSubmission() {
        if (this.hasFormTarget) {
            this.formTarget.addEventListener("submit", this.handleFormSubmit.bind(this))
        }
    }

    setupDebugListeners() {
        if (!this.debugEnabled) return

        // Log clicks on the submit button and whether it's inside the form element
        if (this.hasSubmitButtonTarget) {
            this.submitButtonTarget.addEventListener("click", (e) => {
                const form = this.submitButtonTarget.form
                // eslint-disable-next-line no-console
                console.group("[devvme][project-form] submit button click")
                // eslint-disable-next-line no-console
                console.log("button.disabled:", this.submitButtonTarget.disabled)
                // eslint-disable-next-line no-console
                console.log("button.form exists:", !!form)
                // eslint-disable-next-line no-console
                console.log("button.form === this.formTarget:", this.hasFormTarget ? form === this.formTarget : "(no formTarget)")
                // eslint-disable-next-line no-console
                console.log("event.defaultPrevented:", e.defaultPrevented)
                // eslint-disable-next-line no-console
                console.log("form action/method:", form?.action, form?.method)
                // eslint-disable-next-line no-console
                console.groupEnd()
            })
        }

        // Capture submit events (bubble) to confirm the browser is attempting submission
        if (this.hasFormTarget) {
            this.formTarget.addEventListener("submit", (e) => {
                // eslint-disable-next-line no-console
                console.group("[devvme][project-form] form submit")
                // eslint-disable-next-line no-console
                console.log("event.defaultPrevented:", e.defaultPrevented)
                // eslint-disable-next-line no-console
                console.log("form action/method:", this.formTarget.action, this.formTarget.method)
                // eslint-disable-next-line no-console
                console.log("form elements:", this.formTarget.elements?.length)
                // eslint-disable-next-line no-console
                console.groupEnd()
            })
        }
    }

    isDebugEnabled() {
        try {
            return window?.localStorage?.getItem("devvme_debug_project_form") === "1"
        } catch (_) {
            return false
        }
    }

    initializeAnimations() {
        // Add entrance animations to form sections
        const sections = this.element.querySelectorAll('.form-section')
        sections.forEach((section, index) => {
            section.style.opacity = '0'
            section.style.transform = 'translateY(20px)'
            setTimeout(() => {
                section.style.transition = 'all 0.3s ease-out'
                section.style.opacity = '1'
                section.style.transform = 'translateY(0)'
            }, index * 100)
        })
    }

    handleFormSubmit(event) {
        if (this.debugEnabled) {
            // eslint-disable-next-line no-console
            console.log("[devvme][project-form] handleFormSubmit fired", {
                defaultPrevented: event.defaultPrevented,
                action: this.hasFormTarget ? this.formTarget.action : undefined,
                method: this.hasFormTarget ? this.formTarget.method : undefined
            })
        }
        if (this.hasSubmitButtonTarget) {
            this.showLoadingState()
        }
    }

    showLoadingState() {
        const button = this.submitButtonTarget
        const originalText = button.textContent

        button.disabled = true
        button.innerHTML = `
            <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Saving...
        `

        // Store original text for potential restoration
        button.dataset.originalText = originalText
    }

    resetLoadingState() {
        if (this.hasSubmitButtonTarget && this.submitButtonTarget.dataset.originalText) {
            const button = this.submitButtonTarget
            button.disabled = false
            button.textContent = button.dataset.originalText
            delete button.dataset.originalText
        }
    }

    // Thumbnail Upload Handlers
    previewThumbnail(event) {
        const file = event.target.files[0]
        if (file && this.validateImageFile(file)) {
            this.showLoadingIndicator('thumbnail')
            this.displayThumbnailPreview(file)
        }
    }

    displayThumbnailPreview(file) {
        const reader = new FileReader()
        reader.onload = (e) => {
            this.thumbnailImageTarget.src = e.target.result
            this.thumbnailImageTarget.onload = () => {
                this.hideLoadingIndicator('thumbnail')
                this.animatePreviewIn(this.thumbnailPreviewTarget, this.thumbnailUploadAreaTarget)
            }
        }
        reader.readAsDataURL(file)
    }

    removeThumbnail() {
        // Clear the file input
        const fileInput = this.element.querySelector('#project_thumbnail')
        fileInput.value = ''

        // Animate out and reset
        this.animatePreviewOut(this.thumbnailPreviewTarget, this.thumbnailUploadAreaTarget)
    }

    validateImageFile(file) {
        // Check file type
        if (!file.type.startsWith('image/')) {
            this.showError('Please select a valid image file.')
            return false
        }

        // Check file size
        if (file.size > this.maxImageSizeValue) {
            this.showError(`Image file is too large. Maximum size is ${this.maxImageSizeValue / 1048576}MB.`)
            return false
        }

        return true
    }

    showLoadingIndicator(type) {
        const loadingHtml = `
            <div class="loading-indicator flex items-center justify-center h-24 bg-gray-50 rounded-md border-2 border-dashed border-gray-300">
                <svg class="animate-spin h-8 w-8 text-gray-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                <span class="ml-2 text-gray-500">Processing...</span>
            </div>
        `

        if (type === 'thumbnail') {
            const container = this.thumbnailDropzoneTarget
            container.insertAdjacentHTML('beforeend', loadingHtml)
        } else if (type === 'images') {
            const container = this.imagesDropzoneTarget
            container.insertAdjacentHTML('beforeend', loadingHtml)
        }
    }

    hideLoadingIndicator(type) {
        const indicators = this.element.querySelectorAll('.loading-indicator')
        indicators.forEach(indicator => indicator.remove())
    }

    animatePreviewIn(showElement, hideElement) {
        // Fade out upload area
        hideElement.style.transition = 'opacity 0.3s ease-out'
        hideElement.style.opacity = '0'

        setTimeout(() => {
            hideElement.classList.add('hidden')
            showElement.classList.remove('hidden')

            // Fade in preview
            showElement.style.opacity = '0'
            showElement.style.transform = 'scale(0.95)'
            showElement.style.transition = 'all 0.3s ease-out'

            requestAnimationFrame(() => {
                showElement.style.opacity = '1'
                showElement.style.transform = 'scale(1)'
            })
        }, 300)
    }

    animatePreviewOut(hideElement, showElement) {
        // Fade out preview
        hideElement.style.transition = 'all 0.3s ease-out'
        hideElement.style.opacity = '0'
        hideElement.style.transform = 'scale(0.95)'

        setTimeout(() => {
            hideElement.classList.add('hidden')
            showElement.classList.remove('hidden')

            // Fade in upload area
            showElement.style.opacity = '0'
            showElement.style.transition = 'opacity 0.3s ease-out'

            requestAnimationFrame(() => {
                showElement.style.opacity = '1'
            })
        }, 300)
    }

    // Additional Images Handlers
    previewImages(event) {
        const files = Array.from(event.target.files)
        const validFiles = files.filter(file => this.validateImageFile(file))

        if (validFiles.length > this.maxImagesValue) {
            this.showError(`You can only upload up to ${this.maxImagesValue} images.`)
            return
        }

        if (validFiles.length > 0) {
            this.showLoadingIndicator('images')
            this.displayImagesPreview(validFiles)
        }
    }

    displayImagesPreview(files) {
        this.imagesGridTarget.innerHTML = '' // Clear existing previews
        let loadedCount = 0

        files.forEach((file, index) => {
            if (file.type.startsWith('image/')) {
                const reader = new FileReader()
                reader.onload = (e) => {
                    const imageContainer = this.createImagePreviewElement(e.target.result, index)
                    this.imagesGridTarget.appendChild(imageContainer)

                    // Animate in the image
                    this.animateImageIn(imageContainer)

                    loadedCount++
                    if (loadedCount === files.length) {
                        this.hideLoadingIndicator('images')
                        this.imagesPreviewTarget.classList.remove('hidden')
                    }
                }
                reader.readAsDataURL(file)
            }
        })
    }

    animateImageIn(imageContainer) {
        imageContainer.style.opacity = '0'
        imageContainer.style.transform = 'scale(0.8) translateY(20px)'
        imageContainer.style.transition = 'all 0.4s ease-out'

        requestAnimationFrame(() => {
            imageContainer.style.opacity = '1'
            imageContainer.style.transform = 'scale(1) translateY(0)'
        })
    }

    createImagePreviewElement(src, index) {
        const container = document.createElement('div')
        container.className = 'relative'
        container.innerHTML = `
      <img src="${src}" alt="Preview ${index + 1}" class="w-full h-24 object-cover rounded-md shadow-sm">
      <button type="button" 
              class="absolute top-1 right-1 bg-red-500 text-white rounded-full w-5 h-5 flex items-center justify-center text-xs hover:bg-red-600"
              data-action="click->project-form#removeImage"
              data-index="${index}">
        ×
      </button>
    `
        return container
    }

    removeImage(event) {
        const imageContainer = event.target.closest('.relative')
        const index = parseInt(event.target.dataset.index)
        const fileInput = this.element.querySelector('#project_images')

        // Animate out the image
        imageContainer.style.transition = 'all 0.3s ease-out'
        imageContainer.style.opacity = '0'
        imageContainer.style.transform = 'scale(0.8) translateY(-20px)'

        setTimeout(() => {
            // Create a new FileList without the removed file
            const dt = new DataTransfer()
            const files = Array.from(fileInput.files)

            files.forEach((file, i) => {
                if (i !== index) {
                    dt.items.add(file)
                }
            })

            fileInput.files = dt.files

            // Refresh the preview
            this.displayImagesPreview(Array.from(fileInput.files))
        }, 300)
    }

    showError(message) {
        // Remove any existing error messages
        this.clearErrors()

        // Create error element
        const errorEl = document.createElement('div')
        errorEl.className = 'error-message mt-2 p-3 bg-red-100 border border-red-300 text-red-700 rounded-md'
        errorEl.textContent = message

        // Add to form
        this.element.appendChild(errorEl)

        // Animate in
        errorEl.style.opacity = '0'
        errorEl.style.transform = 'translateY(-10px)'
        errorEl.style.transition = 'all 0.3s ease-out'

        requestAnimationFrame(() => {
            errorEl.style.opacity = '1'
            errorEl.style.transform = 'translateY(0)'
        })

        // Auto-remove after 5 seconds
        setTimeout(() => {
            this.clearErrors()
        }, 5000)
    }

    clearErrors() {
        const errors = this.element.querySelectorAll('.error-message')
        errors.forEach(error => {
            error.style.transition = 'all 0.3s ease-out'
            error.style.opacity = '0'
            error.style.transform = 'translateY(-10px)'
            setTimeout(() => error.remove(), 300)
        })
    }

    // Drag and Drop Handlers
    handleDragOver(event) {
        event.preventDefault()
        const target = event.currentTarget
        target.classList.add('border-blue-400', 'bg-blue-50', 'scale-105')
        target.style.transition = 'all 0.2s ease-out'

        // Add pulsing animation
        target.classList.add('animate-pulse')
    }

    handleDragLeave(event) {
        event.preventDefault()
        const target = event.currentTarget
        target.classList.remove('border-blue-400', 'bg-blue-50', 'scale-105', 'animate-pulse')
        target.style.transition = 'all 0.2s ease-out'
    }

    handleThumbnailDrop(event) {
        event.preventDefault()
        const target = event.currentTarget
        target.classList.remove('border-blue-400', 'bg-blue-50', 'scale-105', 'animate-pulse')

        const files = event.dataTransfer.files
        if (files.length > 0 && this.validateImageFile(files[0])) {
            const fileInput = this.element.querySelector('#project_thumbnail')
            const dt = new DataTransfer()
            dt.items.add(files[0])
            fileInput.files = dt.files

            this.showLoadingIndicator('thumbnail')
            this.displayThumbnailPreview(files[0])

            // Show success feedback
            this.showDropSuccess(target)
        }
    }

    handleImagesDrop(event) {
        event.preventDefault()
        const target = event.currentTarget
        target.classList.remove('border-blue-400', 'bg-blue-50', 'scale-105', 'animate-pulse')

        const files = Array.from(event.dataTransfer.files)
        const validFiles = files.filter(file => this.validateImageFile(file))

        if (validFiles.length > this.maxImagesValue) {
            this.showError(`You can only upload up to ${this.maxImagesValue} images.`)
            return
        }

        if (validFiles.length > 0) {
            const fileInput = this.element.querySelector('#project_images')
            const dt = new DataTransfer()
            validFiles.forEach(file => dt.items.add(file))
            fileInput.files = dt.files

            this.showLoadingIndicator('images')
            this.displayImagesPreview(validFiles)

            // Show success feedback
            this.showDropSuccess(target)
        }
    }

    showDropSuccess(target) {
        target.classList.add('border-green-400', 'bg-green-50')
        setTimeout(() => {
            target.classList.remove('border-green-400', 'bg-green-50')
        }, 1000)
    }
}
