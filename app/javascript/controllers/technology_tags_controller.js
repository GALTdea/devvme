import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="technology-tags"
export default class extends Controller {
    static targets = ["container", "input", "tagsContainer", "hiddenField", "suggestions"]
    static values = { technologies: Array }

    // Common technologies and skills organized by category
    static commonTechnologies = {
        "Frontend": [
            "HTML", "CSS", "JavaScript", "TypeScript", "React", "Vue.js", "Angular", "Svelte",
            "Tailwind CSS", "Bootstrap", "Sass", "SCSS", "Less", "Webpack", "Vite", "Parcel",
            "Next.js", "Nuxt.js", "Gatsby", "Astro", "jQuery", "D3.js", "Three.js"
        ],
        "Backend": [
            "Ruby", "Rails", "Python", "Django", "Flask", "FastAPI", "Node.js", "Express",
            "PHP", "Laravel", "Symfony", "Java", "Spring Boot", "C#", ".NET", "ASP.NET",
            "Go", "Gin", "Rust", "Actix", "Elixir", "Phoenix", "Clojure", "Scala"
        ],
        "Database": [
            "PostgreSQL", "MySQL", "SQLite", "MongoDB", "Redis", "Elasticsearch",
            "DynamoDB", "Cassandra", "Neo4j", "Firebase", "Supabase", "PlanetScale"
        ],
        "DevOps & Cloud": [
            "Docker", "Kubernetes", "AWS", "Azure", "Google Cloud", "Heroku", "Vercel",
            "Netlify", "DigitalOcean", "Linode", "Terraform", "Ansible", "Jenkins",
            "GitHub Actions", "GitLab CI", "CircleCI"
        ],
        "Mobile": [
            "React Native", "Flutter", "Swift", "Kotlin", "Ionic", "Cordova",
            "Xamarin", "Unity", "Unreal Engine"
        ],
        "Tools & Others": [
            "Git", "GitHub", "GitLab", "Bitbucket", "Figma", "Sketch", "Adobe XD",
            "VS Code", "Vim", "Emacs", "Jira", "Trello", "Notion", "Slack",
            "Postman", "Insomnia", "GraphQL", "REST API", "WebSocket", "gRPC"
        ]
    }

    connect() {
        this.tags = this.technologiesValue || []
        this.filteredSuggestions = []
        this.selectedSuggestionIndex = -1
        this.renderTags()
        this.updateHiddenField()
        this.setupEventListeners()
    }

    technologiesValueChanged() {
        // Handle null, undefined, or empty values
        if (this.technologiesValue === null || this.technologiesValue === undefined) {
            this.tags = []
        } else if (Array.isArray(this.technologiesValue)) {
            this.tags = this.technologiesValue
        } else {
            this.tags = []
        }
        this.renderTags()
        this.updateHiddenField()
    }

    focusInput() {
        this.inputTarget.focus()
    }

    setupEventListeners() {
        // Handle input changes for autocomplete
        this.inputTarget.addEventListener('input', () => this.handleInput())

        // Handle clicks outside to close suggestions
        document.addEventListener('click', (e) => {
            if (!this.containerTarget.contains(e.target)) {
                this.hideSuggestions()
            }
        })

        // Close on mousedown on dropdown background so overlapped elements (e.g. Submit button)
        // can receive the subsequent click once the dropdown is hidden
        document.addEventListener('mousedown', this.boundHandleDropdownBackdropMousedown)
    }

    disconnect() {
        document.removeEventListener('mousedown', this.boundHandleDropdownBackdropMousedown)
    }

    get boundHandleDropdownBackdropMousedown() {
        if (!this._boundHandleDropdownBackdropMousedown) {
            this._boundHandleDropdownBackdropMousedown = this.handleDropdownBackdropMousedown.bind(this)
        }
        return this._boundHandleDropdownBackdropMousedown
    }

    handleDropdownBackdropMousedown(e) {
        if (!this.hasSuggestionsTarget || this.suggestionsTarget.classList.contains('hidden')) return
        if (this.suggestionsTarget.contains(e.target) && !e.target.closest('.cursor-pointer')) {
            this.hideSuggestions()
        }
    }

    handleInput() {
        const value = this.inputTarget.value.trim()

        if (value.length === 0) {
            this.hideSuggestions()
            return
        }

        this.filterSuggestions(value)
        this.showSuggestions()
    }

    filterSuggestions(query) {
        const allTechnologies = Object.values(this.constructor.commonTechnologies).flat()
        const queryLower = query.toLowerCase()

        this.filteredSuggestions = allTechnologies
            .filter(tech =>
                tech.toLowerCase().includes(queryLower) &&
                !this.tags.includes(tech)
            )
            .slice(0, 8) // Limit to 8 suggestions
    }

    showSuggestions() {
        if (this.filteredSuggestions.length === 0) {
            this.hideSuggestions()
            return
        }

        if (!this.hasSuggestionsTarget) {
            this.createSuggestionsContainer()
        }

        this.renderSuggestions()
        this.suggestionsTarget.classList.remove('hidden')
        this.selectedSuggestionIndex = -1
    }

    hideSuggestions() {
        if (this.hasSuggestionsTarget) {
            this.suggestionsTarget.classList.add('hidden')
        }
    }

    createSuggestionsContainer() {
        const suggestionsDiv = document.createElement('div')
        suggestionsDiv.className = 'absolute z-10 w-full mt-1 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-60 overflow-y-auto hidden'
        suggestionsDiv.setAttribute('data-technology-tags-target', 'suggestions')

        this.containerTarget.style.position = 'relative'
        this.containerTarget.appendChild(suggestionsDiv)
    }

    renderSuggestions() {
        if (!this.hasSuggestionsTarget) return

        this.suggestionsTarget.innerHTML = ''

        this.filteredSuggestions.forEach((suggestion, index) => {
            const suggestionElement = document.createElement('div')
            suggestionElement.className = 'px-3 py-2 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-600 text-sm'
            suggestionElement.textContent = suggestion
            suggestionElement.setAttribute('data-index', index)
            suggestionElement.addEventListener('click', () => this.selectSuggestion(suggestion))

            this.suggestionsTarget.appendChild(suggestionElement)
        })
    }

    selectSuggestion(suggestion) {
        this.inputTarget.value = suggestion
        this.addTag()
        this.hideSuggestions()
    }

    handleKeydown(event) {
        switch (event.key) {
            case 'Enter':
                event.preventDefault()
                if (this.selectedSuggestionIndex >= 0 && this.hasSuggestionsTarget && !this.suggestionsTarget.classList.contains('hidden')) {
                    this.selectSuggestion(this.filteredSuggestions[this.selectedSuggestionIndex])
                } else {
                    this.addTag()
                }
                break
            case 'ArrowDown':
                event.preventDefault()
                this.navigateSuggestions(1)
                break
            case 'ArrowUp':
                event.preventDefault()
                this.navigateSuggestions(-1)
                break
            case 'Escape':
                this.hideSuggestions()
                break
            case 'Backspace':
                if (this.inputTarget.value === '' && this.tags.length > 0) {
                    this.removeTag(this.tags.length - 1)
                }
                break
            case ',':
                // Allow comma-separated input
                event.preventDefault()
                this.addTag()
                break
        }
    }

    navigateSuggestions(direction) {
        if (!this.hasSuggestionsTarget || this.suggestionsTarget.classList.contains('hidden')) {
            return
        }

        const maxIndex = this.filteredSuggestions.length - 1
        this.selectedSuggestionIndex += direction

        if (this.selectedSuggestionIndex < 0) {
            this.selectedSuggestionIndex = maxIndex
        } else if (this.selectedSuggestionIndex > maxIndex) {
            this.selectedSuggestionIndex = 0
        }

        this.highlightSuggestion()
    }

    highlightSuggestion() {
        if (!this.hasSuggestionsTarget) return

        const suggestions = this.suggestionsTarget.querySelectorAll('[data-index]')
        suggestions.forEach((suggestion, index) => {
            if (index === this.selectedSuggestionIndex) {
                suggestion.classList.add('bg-blue-100', 'dark:bg-blue-900')
            } else {
                suggestion.classList.remove('bg-blue-100', 'dark:bg-blue-900')
            }
        })
    }

    handleBlur() {
        if (this.inputTarget.value.trim()) {
            this.addTag()
        }
    }

    addTag() {
        const value = this.inputTarget.value.trim()

        if (!value) return

        // Handle comma-separated input
        const values = value.split(',').map(v => v.trim()).filter(v => v.length > 0)

        if (values.length > 1) {
            // Add multiple tags at once
            values.forEach(tagValue => this.addSingleTag(tagValue))
        } else {
            this.addSingleTag(value)
        }

        this.inputTarget.value = ''
        this.hideSuggestions()
    }

    addSingleTag(value) {
        // Check for duplicates
        if (this.tags.includes(value)) {
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
        this.renderTags()
        this.updateHiddenField()
    }

    addQuickSkill(event) {
        const skill = event.target.dataset.skill
        this.addSingleTag(skill)
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
        tagElement.className = 'inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200 border border-blue-200 dark:border-blue-700'

        tagElement.innerHTML = `
      ${this.escapeHtml(tag)}
      <button type="button" 
              class="ml-2 h-4 w-4 rounded-full inline-flex items-center justify-center text-blue-400 hover:bg-blue-200 dark:hover:bg-blue-700 hover:text-blue-600 dark:hover:text-blue-100 focus:outline-none focus:bg-blue-500 focus:text-white transition-colors"
              data-action="click->technology-tags#removeTagByButton"
              data-index="${index}"
              title="Remove ${this.escapeHtml(tag)}">
        <svg class="h-2.5 w-2.5" stroke="currentColor" fill="none" viewBox="0 0 8 8">
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
        errorDiv.className = 'mt-1 text-sm text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 px-2 py-1 rounded border border-red-200 dark:border-red-800'
        errorDiv.textContent = message

        // Remove any existing error message
        const existingError = this.containerTarget.parentNode.querySelector('.text-red-600')
        if (existingError) {
            existingError.remove()
        }

        // Add the error message
        this.containerTarget.parentNode.appendChild(errorDiv)

        // Add a subtle shake animation to the input
        this.containerTarget.classList.add('animate-pulse')
        setTimeout(() => {
            this.containerTarget.classList.remove('animate-pulse')
        }, 500)

        // Remove the error message after 4 seconds
        setTimeout(() => {
            if (errorDiv.parentNode) {
                errorDiv.remove()
            }
        }, 4000)
    }

    escapeHtml(text) {
        const div = document.createElement('div')
        div.textContent = text
        return div.innerHTML
    }
}