import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="project-form"
export default class extends Controller {
    static targets = ["thumbnailDropzone", "thumbnailPreview", "thumbnailImage", "thumbnailUploadArea",
        "imagesDropzone", "imagesPreview", "imagesGrid"]

    connect() {
        console.log("Project form controller connected")
    }

    // Thumbnail Upload Handlers
    previewThumbnail(event) {
        const file = event.target.files[0]
        if (file && file.type.startsWith('image/')) {
            this.displayThumbnailPreview(file)
        }
    }

    displayThumbnailPreview(file) {
        const reader = new FileReader()
        reader.onload = (e) => {
            this.thumbnailImageTarget.src = e.target.result
            this.thumbnailPreviewTarget.classList.remove('hidden')
            this.thumbnailUploadAreaTarget.classList.add('hidden')
        }
        reader.readAsDataURL(file)
    }

    removeThumbnail() {
        // Clear the file input
        const fileInput = this.element.querySelector('#project_thumbnail')
        fileInput.value = ''

        // Reset the preview
        this.thumbnailPreviewTarget.classList.add('hidden')
        this.thumbnailUploadAreaTarget.classList.remove('hidden')
    }

    // Additional Images Handlers
    previewImages(event) {
        const files = Array.from(event.target.files)
        this.displayImagesPreview(files)
    }

    displayImagesPreview(files) {
        this.imagesGridTarget.innerHTML = '' // Clear existing previews

        files.forEach((file, index) => {
            if (file.type.startsWith('image/')) {
                const reader = new FileReader()
                reader.onload = (e) => {
                    const imageContainer = this.createImagePreviewElement(e.target.result, index)
                    this.imagesGridTarget.appendChild(imageContainer)
                }
                reader.readAsDataURL(file)
            }
        })

        this.imagesPreviewTarget.classList.remove('hidden')
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
        const index = parseInt(event.target.dataset.index)
        const fileInput = this.element.querySelector('#project_images')

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
    }

    // Drag and Drop Handlers
    handleDragOver(event) {
        event.preventDefault()
        event.currentTarget.classList.add('border-blue-400', 'bg-blue-50')
    }

    handleDragLeave(event) {
        event.preventDefault()
        event.currentTarget.classList.remove('border-blue-400', 'bg-blue-50')
    }

    handleThumbnailDrop(event) {
        event.preventDefault()
        event.currentTarget.classList.remove('border-blue-400', 'bg-blue-50')

        const files = event.dataTransfer.files
        if (files.length > 0 && files[0].type.startsWith('image/')) {
            const fileInput = this.element.querySelector('#project_thumbnail')
            const dt = new DataTransfer()
            dt.items.add(files[0])
            fileInput.files = dt.files

            this.displayThumbnailPreview(files[0])
        }
    }

    handleImagesDrop(event) {
        event.preventDefault()
        event.currentTarget.classList.remove('border-blue-400', 'bg-blue-50')

        const files = Array.from(event.dataTransfer.files).filter(file => file.type.startsWith('image/'))
        if (files.length > 0) {
            const fileInput = this.element.querySelector('#project_images')
            const dt = new DataTransfer()
            files.forEach(file => dt.items.add(file))
            fileInput.files = dt.files

            this.displayImagesPreview(files)
        }
    }
}
