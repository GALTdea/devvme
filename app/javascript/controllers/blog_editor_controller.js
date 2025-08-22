import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"

// Simple function for basic syntax highlighting without external dependencies
function simpleSyntaxHighlight(code, language) {
    // Basic highlighting for common languages
    const patterns = {
        javascript: [
            { pattern: /(function|const|let|var|if|else|for|while|return|class|import|export)\b/g, class: 'keyword' },
            { pattern: /(["'])((?:\\.|(?!\1)[^\\])*?)\1/g, class: 'string' },
            { pattern: /\/\*[\s\S]*?\*\/|\/\/.*$/gm, class: 'comment' }
        ],
        ruby: [
            { pattern: /(def|class|module|if|else|elsif|end|return|require|include)\b/g, class: 'keyword' },
            { pattern: /(["'])((?:\\.|(?!\1)[^\\])*?)\1/g, class: 'string' },
            { pattern: /#.*$/gm, class: 'comment' }
        ],
        python: [
            { pattern: /(def|class|if|else|elif|for|while|return|import|from|as)\b/g, class: 'keyword' },
            { pattern: /(["'])((?:\\.|(?!\1)[^\\])*?)\1/g, class: 'string' },
            { pattern: /#.*$/gm, class: 'comment' }
        ]
    }

    if (patterns[language]) {
        let highlighted = code
        patterns[language].forEach(({ pattern, class: className }) => {
            highlighted = highlighted.replace(pattern, `<span class="${className}">$&</span>`)
        })
        return highlighted
    }

    return code
}

// Configure marked with simple syntax highlighting
marked.setOptions({
    highlight: function (code, language) {
        return simpleSyntaxHighlight(code, language)
    },
    breaks: true,
    gfm: true
});

export default class extends Controller {
    static targets = ["content", "preview", "title", "excerpt", "publishedToggle", "publishedAt", "autosaveStatus", "wordCount", "readingTime"]
    static values = {
        autosaveUrl: String,
        autosaveEnabled: { type: Boolean, default: true }
    }

    connect() {
        this.autosaveTimer = null
        this.lastSavedContent = this.contentTarget.value
        this.previewMode = false

        // Initialize word count and reading time
        this.updateStats()

        // Set up autosave
        if (this.autosaveEnabledValue) {
            this.setupAutosave()
        }

        // Handle published toggle
        this.updatePublishedAtVisibility()
    }

    disconnect() {
        if (this.autosaveTimer) {
            clearTimeout(this.autosaveTimer)
        }
    }

    // Toggle between edit and preview modes
    togglePreview() {
        this.previewMode = !this.previewMode

        if (this.previewMode) {
            this.showPreview()
        } else {
            this.showEditor()
        }
    }

    showPreview() {
        const content = this.contentTarget.value
        const html = marked.parse(content)

        this.previewTarget.innerHTML = html
        this.previewTarget.classList.remove('hidden')
        this.contentTarget.classList.add('hidden')

        // Update preview button
        const previewBtn = this.element.querySelector('[data-action*="togglePreview"]')
        if (previewBtn) {
            previewBtn.textContent = 'Edit'
            previewBtn.classList.remove('bg-gray-600', 'hover:bg-gray-700')
            previewBtn.classList.add('bg-blue-600', 'hover:bg-blue-700')
        }
    }

    showEditor() {
        this.previewTarget.classList.add('hidden')
        this.contentTarget.classList.remove('hidden')

        // Update preview button
        const previewBtn = this.element.querySelector('[data-action*="togglePreview"]')
        if (previewBtn) {
            previewBtn.textContent = 'Preview'
            previewBtn.classList.remove('bg-blue-600', 'hover:bg-blue-700')
            previewBtn.classList.add('bg-gray-600', 'hover:bg-gray-700')
        }

        // Focus back to textarea
        this.contentTarget.focus()
    }

    // Update word count and reading time
    updateStats() {
        const content = this.contentTarget.value
        const words = content.trim().split(/\s+/).filter(word => word.length > 0).length
        const readingTime = Math.max(1, Math.ceil(words / 200))

        if (this.hasWordCountTarget) {
            this.wordCountTarget.textContent = `${words} words`
        }

        if (this.hasReadingTimeTarget) {
            this.readingTimeTarget.textContent = `${readingTime} min read`
        }
    }

    // Content changed handler
    contentChanged() {
        this.updateStats()
        this.scheduleAutosave()
    }

    // Title or excerpt changed handler
    fieldChanged() {
        this.scheduleAutosave()
    }

    // Setup autosave functionality
    setupAutosave() {
        this.contentTarget.addEventListener('input', () => this.contentChanged())

        if (this.hasTitleTarget) {
            this.titleTarget.addEventListener('input', () => this.fieldChanged())
        }

        if (this.hasExcerptTarget) {
            this.excerptTarget.addEventListener('input', () => this.fieldChanged())
        }
    }

    // Schedule autosave
    scheduleAutosave() {
        if (!this.autosaveEnabledValue || !this.autosaveUrlValue) return

        if (this.autosaveTimer) {
            clearTimeout(this.autosaveTimer)
        }

        this.autosaveTimer = setTimeout(() => {
            this.performAutosave()
        }, 2000) // Autosave after 2 seconds of inactivity
    }

    // Perform autosave
    async performAutosave() {
        const currentContent = this.getCurrentFormData()

        // Only save if content has changed
        if (JSON.stringify(currentContent) === JSON.stringify(this.lastSavedContent)) {
            return
        }

        try {
            this.showAutosaveStatus('Saving...', 'saving')

            const response = await fetch(this.autosaveUrlValue, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
                },
                body: JSON.stringify({
                    blog_post: currentContent
                })
            })

            const result = await response.json()

            if (result.status === 'success') {
                this.lastSavedContent = currentContent
                this.showAutosaveStatus(`Saved ${result.saved_at}`, 'success')
            } else {
                this.showAutosaveStatus('Save failed', 'error')
                console.error('Autosave failed:', result.errors)
            }
        } catch (error) {
            this.showAutosaveStatus('Save failed', 'error')
            console.error('Autosave error:', error)
        }
    }

    // Get current form data
    getCurrentFormData() {
        return {
            title: this.hasTitleTarget ? this.titleTarget.value : '',
            content: this.contentTarget.value,
            excerpt: this.hasExcerptTarget ? this.excerptTarget.value : ''
        }
    }

    // Show autosave status
    showAutosaveStatus(message, type) {
        if (!this.hasAutosaveStatusTarget) return

        this.autosaveStatusTarget.textContent = message

        // Remove existing classes
        this.autosaveStatusTarget.classList.remove('text-gray-500', 'text-green-600', 'text-red-600', 'text-blue-600')

        // Add appropriate class based on type
        switch (type) {
            case 'saving':
                this.autosaveStatusTarget.classList.add('text-blue-600')
                break
            case 'success':
                this.autosaveStatusTarget.classList.add('text-green-600')
                break
            case 'error':
                this.autosaveStatusTarget.classList.add('text-red-600')
                break
            default:
                this.autosaveStatusTarget.classList.add('text-gray-500')
        }

        // Clear status after a few seconds (except for errors)
        if (type !== 'error') {
            setTimeout(() => {
                if (this.hasAutosaveStatusTarget) {
                    this.autosaveStatusTarget.textContent = ''
                }
            }, 3000)
        }
    }

    // Insert markdown formatting
    insertMarkdown(event) {
        const button = event.currentTarget
        const format = button.dataset.format

        this.insertTextAtCursor(format)
    }

    // Insert text at cursor position
    insertTextAtCursor(text) {
        const textarea = this.contentTarget
        const start = textarea.selectionStart
        const end = textarea.selectionEnd
        const currentValue = textarea.value

        // Handle different markdown formats
        let before = '', after = '', selectedText = currentValue.substring(start, end)

        switch (text) {
            case 'bold':
                before = '**'
                after = '**'
                if (!selectedText) selectedText = 'bold text'
                break
            case 'italic':
                before = '*'
                after = '*'
                if (!selectedText) selectedText = 'italic text'
                break
            case 'code':
                before = '`'
                after = '`'
                if (!selectedText) selectedText = 'code'
                break
            case 'codeblock':
                before = '```\n'
                after = '\n```'
                if (!selectedText) selectedText = 'code block'
                break
            case 'link':
                before = '['
                after = '](url)'
                if (!selectedText) selectedText = 'link text'
                break
            case 'h1':
                before = '# '
                after = ''
                if (!selectedText) selectedText = 'Heading 1'
                break
            case 'h2':
                before = '## '
                after = ''
                if (!selectedText) selectedText = 'Heading 2'
                break
            case 'h3':
                before = '### '
                after = ''
                if (!selectedText) selectedText = 'Heading 3'
                break
            case 'ul':
                before = '- '
                after = ''
                if (!selectedText) selectedText = 'List item'
                break
            case 'ol':
                before = '1. '
                after = ''
                if (!selectedText) selectedText = 'List item'
                break
            case 'quote':
                before = '> '
                after = ''
                if (!selectedText) selectedText = 'Quote text'
                break
            default:
                before = text
                after = ''
        }

        const newValue = currentValue.substring(0, start) + before + selectedText + after + currentValue.substring(end)
        textarea.value = newValue

        // Set cursor position
        const newCursorPos = start + before.length + selectedText.length
        textarea.setSelectionRange(newCursorPos, newCursorPos)
        textarea.focus()

        // Trigger change event
        this.contentChanged()
    }

    // Handle published toggle
    publishedToggleChanged() {
        this.updatePublishedAtVisibility()
    }

    updatePublishedAtVisibility() {
        if (!this.hasPublishedToggleTarget || !this.hasPublishedAtTarget) return

        const publishedAtContainer = this.publishedAtTarget.closest('.published-at-container')
        if (!publishedAtContainer) return

        if (this.publishedToggleTarget.checked) {
            publishedAtContainer.classList.remove('hidden')
            // Set current datetime if empty
            if (!this.publishedAtTarget.value) {
                const now = new Date()
                const offset = now.getTimezoneOffset() * 60000
                const localISOTime = new Date(now.getTime() - offset).toISOString().slice(0, 16)
                this.publishedAtTarget.value = localISOTime
            }
        } else {
            publishedAtContainer.classList.add('hidden')
        }
    }

    // Handle keyboard shortcuts
    keydown(event) {
        // Ctrl/Cmd + B for bold
        if ((event.ctrlKey || event.metaKey) && event.key === 'b') {
            event.preventDefault()
            this.insertTextAtCursor('bold')
        }

        // Ctrl/Cmd + I for italic
        if ((event.ctrlKey || event.metaKey) && event.key === 'i') {
            event.preventDefault()
            this.insertTextAtCursor('italic')
        }

        // Ctrl/Cmd + K for link
        if ((event.ctrlKey || event.metaKey) && event.key === 'k') {
            event.preventDefault()
            this.insertTextAtCursor('link')
        }

        // Tab for code indentation
        if (event.key === 'Tab') {
            event.preventDefault()
            this.insertTextAtCursor('  ') // Insert 2 spaces
        }
    }
}
