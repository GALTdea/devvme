import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="technology-tags"
export default class extends Controller {
    static targets = ["container", "input", "tagsContainer", "hiddenField"]
    static values = { technologies: Array }

    connect() {
        this.tags = this.technologiesValue || []
        this.renderTags()
        this.updateHiddenField()
    }

    technologiesValueChanged() {
        this.tags = this.technologiesValue || []
        this.renderTags()
        this.updateHiddenField()
    }

    focusInput() {
        this.inputTarget.focus()
    }

    handleKeydown(event) {
        switch (event.key) {
            case 'Enter':
                event.preventDefault()
                this.addTag()
                break
            case 'Backspace':
                if (this.inputTarget.value === '' && this.tags.length > 0) {
                    this.removeTag(this.tags.length - 1)
                }
                break
        }
    }

    handleBlur() {
        if (this.inputTarget.value.trim()) {
            this.addTag()
        }
    }

    addTag() {
        const value = this.inputTarget.value.trim()

        if (!value) return

        // Check for duplicates
        if (this.tags.includes(value)) {
            this.inputTarget.value = ''
            this.showError("Technology already added")
            return
        }

        // Check tag length
        if (value.length > 50) {
            this.showError("Technology name is too long (maximum 50 characters)")
            return
        }

        // Check maximum number of tags
        if (this.tags.length >= 10) {
            this.showError("Maximum 10 technologies allowed")
            return
        }

        this.tags.push(value)
        this.inputTarget.value = ''
        this.renderTags()
        this.updateHiddenField()
    }

    removeTag(index) {
        this.tags.splice(index, 1)
        this.renderTags()
        this.updateHiddenField()
    }

    renderTags() {
        this.tagsContainerTarget.innerHTML = ''

        this.tags.forEach((tag, index) => {
            const tagElement = this.createTagElement(tag, index)
            this.tagsContainerTarget.appendChild(tagElement)
        })
    }

    createTagElement(tag, index) {
        const tagElement = document.createElement('span')
        tagElement.className = 'inline-flex items-center px-2 py-1 rounded-md text-sm font-medium bg-blue-100 text-blue-800'

        tagElement.innerHTML = `
      ${this.escapeHtml(tag)}
      <button type="button" 
              class="ml-1 h-4 w-4 rounded-full inline-flex items-center justify-center text-blue-400 hover:bg-blue-200 hover:text-blue-500 focus:outline-none focus:bg-blue-500 focus:text-white"
              data-action="click->technology-tags#removeTagByButton"
              data-index="${index}">
        <svg class="h-2 w-2" stroke="currentColor" fill="none" viewBox="0 0 8 8">
          <path stroke-linecap="round" stroke-width="1.5" d="m1 1 6 6m0-6-6 6"/>
        </svg>
      </button>
    `

        return tagElement
    }

    removeTagByButton(event) {
        const index = parseInt(event.target.closest('button').dataset.index)
        this.removeTag(index)
    }

    updateHiddenField() {
        if (this.hasHiddenFieldTarget) {
            this.hiddenFieldTarget.value = this.tags.join(', ')
        }
    }

    showError(message) {
        // Create a temporary error message
        const errorDiv = document.createElement('div')
        errorDiv.className = 'mt-1 text-sm text-red-600'
        errorDiv.textContent = message

        // Remove any existing error message
        const existingError = this.containerTarget.parentNode.querySelector('.text-red-600')
        if (existingError) {
            existingError.remove()
        }

        // Add the error message
        this.containerTarget.parentNode.appendChild(errorDiv)

        // Remove the error message after 3 seconds
        setTimeout(() => {
            if (errorDiv.parentNode) {
                errorDiv.remove()
            }
        }, 3000)
    }

    escapeHtml(text) {
        const div = document.createElement('div')
        div.textContent = text
        return div.innerHTML
    }
}