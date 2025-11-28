import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"
import TurndownService from "turndown"

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
    static targets = [
        "content", "preview", "title", "excerpt", "publishedToggle", "publishedAt", 
        "autosaveStatus", "wordCount", "readingTime", "editorMode", "editorModeToggle",
        "editorModeLabel", "markdownEditor", "richTextEditor", "richTextContent",
        "markdownToolbar", "editorHelp"
    ]
    static values = {
        autosaveUrl: String,
        autosaveEnabled: { type: Boolean, default: true },
        editorMode: { type: String, default: 'markdown' }
    }

    connect() {
        this.autosaveTimer = null
        this.lastSavedContent = this.getCurrentFormData()
        this.previewMode = false

        // Initialize Turndown service for HTML to Markdown conversion
        this.turndownService = new TurndownService({
            headingStyle: 'atx',
            codeBlockStyle: 'fenced',
            bulletListMarker: '-',
            emDelimiter: '*',
            strongDelimiter: '**'
        })

        // Initialize editor mode
        this.initializeEditorMode()

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

    // Initialize editor mode
    initializeEditorMode() {
        // Get initial mode from hidden field or value
        let mode = this.editorModeValue || 'markdown'
        
        // If we have an editor mode target, use its value
        if (this.hasEditorModeTarget && this.editorModeTarget.value) {
            mode = this.editorModeTarget.value
            this.editorModeValue = mode
        }
        
        this.showEditorMode(mode)
    }

    // Toggle between markdown and rich text editor
    toggleEditorMode() {
        const currentMode = this.editorModeValue
        const newMode = currentMode === 'markdown' ? 'rich_text' : 'markdown'
        
        // Convert content when switching modes
        if (this.hasContent()) {
            try {
                if (currentMode === 'markdown') {
                    // Converting from Markdown to Rich Text
                    this.convertMarkdownToRichText()
                } else {
                    // Converting from Rich Text to Markdown
                    this.convertRichTextToMarkdown()
                }
            } catch (error) {
                console.error('Error converting content:', error)
                const confirmMessage = `Error converting content. Switch anyway? (You may lose formatting)`
                if (!confirm(confirmMessage)) {
                    return
                }
            }
        }

        this.editorModeValue = newMode
        if (this.hasEditorModeTarget) {
            this.editorModeTarget.value = newMode
        }
        this.showEditorMode(newMode)
        this.updateStats()
        
        // Update last saved content after conversion
        this.lastSavedContent = this.getCurrentFormData()
    }

    // Convert Markdown to Rich Text (HTML)
    convertMarkdownToRichText() {
        if (!this.hasContentTarget) return

        const markdownContent = this.contentTarget.value.trim()
        if (!markdownContent) return

        // Convert markdown to HTML
        const htmlContent = marked.parse(markdownContent)

        // Set HTML in Trix editor
        // Trix editor uses the value property to set content
        if (this.hasRichTextContentTarget) {
            // Wait for editor to be ready if switching modes
            setTimeout(() => {
                this.richTextContentTarget.value = htmlContent
            }, 50)
        }
    }

    // Convert Rich Text (HTML) to Markdown
    convertRichTextToMarkdown() {
        if (!this.hasRichTextContentTarget) return

        // Get HTML content from Trix editor
        // Trix stores HTML in the value property
        const htmlContent = this.richTextContentTarget.value || ''
        
        if (!htmlContent.trim()) return

        // Convert HTML to Markdown
        const markdownContent = this.turndownService.turndown(htmlContent)

        // Set markdown in textarea
        if (this.hasContentTarget) {
            this.contentTarget.value = markdownContent
        }
    }

    // Show appropriate editor based on mode
    showEditorMode(mode) {
        const isMarkdown = mode === 'markdown'

        // Show/hide editors
        if (this.hasMarkdownEditorTarget) {
            this.markdownEditorTarget.classList.toggle('hidden', !isMarkdown)
        }
        if (this.hasRichTextEditorTarget) {
            this.richTextEditorTarget.classList.toggle('hidden', isMarkdown)
        }

        // Show/hide markdown toolbar
        if (this.hasMarkdownToolbarTarget) {
            this.markdownToolbarTarget.classList.toggle('hidden', !isMarkdown)
        }

        // Update editor mode label
        if (this.hasEditorModeLabelTarget) {
            this.editorModeLabelTarget.textContent = isMarkdown ? 'Markdown' : 'Rich Text'
        }

        // Update help text
        if (this.hasEditorHelpTarget) {
            if (isMarkdown) {
                this.editorHelpTarget.innerHTML = '<span class="hidden sm:inline">Use Markdown for formatting. </span><a href="https://www.markdownguide.org/basic-syntax/" target="_blank" class="text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300">Markdown guide</a>'
            } else {
                this.editorHelpTarget.innerHTML = '<span class="hidden sm:inline">Rich text editor. Format your content using the toolbar above.</span>'
            }
        }

        // Hide preview button in rich text mode
        const previewBtn = this.element.querySelector('[data-action*="togglePreview"]')
        if (previewBtn) {
            previewBtn.classList.toggle('hidden', !isMarkdown)
        }

        // Hide preview if in rich text mode
        if (!isMarkdown && this.previewMode) {
            this.togglePreview()
        }
    }

    // Check if there's any content
    hasContent() {
        if (this.editorModeValue === 'markdown') {
            return this.hasContentTarget && this.contentTarget && this.contentTarget.value.trim().length > 0
        } else {
            // For rich text, check if Trix editor has content
            if (this.hasRichTextContentTarget && this.richTextContentTarget) {
                const trixEditor = this.richTextContentTarget.editor
                if (trixEditor) {
                    const content = trixEditor.getDocument().toString()
                    return content.trim().length > 0
                }
            }
        }
        return false
    }

    // Toggle between edit and preview modes (Markdown only)
    togglePreview() {
        // Only allow preview in markdown mode
        if (this.editorModeValue !== 'markdown') {
            return
        }

        this.previewMode = !this.previewMode

        if (this.previewMode) {
            this.showPreview()
        } else {
            this.showEditor()
        }
    }

    showPreview() {
        if (!this.hasContentTarget) return

        const content = this.contentTarget.value
        const html = marked.parse(content)

        if (this.hasPreviewTarget) {
        this.previewTarget.innerHTML = html
        this.previewTarget.classList.remove('hidden')
        this.contentTarget.classList.add('hidden')
        }

        // Update preview button
        const previewBtn = this.element.querySelector('[data-action*="togglePreview"]')
        if (previewBtn) {
            previewBtn.textContent = 'Edit'
            previewBtn.classList.remove('bg-gray-600', 'hover:bg-gray-700')
            previewBtn.classList.add('bg-blue-600', 'hover:bg-blue-700')
        }
    }

    showEditor() {
        if (this.hasPreviewTarget) {
        this.previewTarget.classList.add('hidden')
        }
        if (this.hasContentTarget) {
        this.contentTarget.classList.remove('hidden')
        }

        // Update preview button
        const previewBtn = this.element.querySelector('[data-action*="togglePreview"]')
        if (previewBtn) {
            previewBtn.textContent = 'Preview'
            previewBtn.classList.remove('bg-blue-600', 'hover:bg-blue-700')
            previewBtn.classList.add('bg-gray-600', 'hover:bg-gray-700')
        }

        // Focus back to textarea
        if (this.hasContentTarget) {
        this.contentTarget.focus()
        }
    }

    // Update word count and reading time
    updateStats() {
        let textContent = ''
        
        if (this.editorModeValue === 'markdown' && this.hasContentTarget) {
            textContent = this.contentTarget.value
        } else if (this.editorModeValue === 'rich_text' && this.hasRichTextContentTarget) {
            // Get plain text from Trix editor
            const trixEditor = this.richTextContentTarget.editor
            if (trixEditor) {
                textContent = trixEditor.getDocument().toString()
            }
        }

        // Strip HTML tags if present (for rich text)
        const tempDiv = document.createElement('div')
        tempDiv.innerHTML = textContent
        const plainText = tempDiv.textContent || tempDiv.innerText || ''
        
        const words = plainText.trim().split(/\s+/).filter(word => word.length > 0).length
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
        // Markdown editor
        if (this.hasContentTarget) {
        this.contentTarget.addEventListener('input', () => this.contentChanged())
        }

        // Rich text editor (Trix)
        if (this.hasRichTextContentTarget) {
            this.richTextContentTarget.addEventListener('trix-change', () => this.richTextChanged())
        }

        if (this.hasTitleTarget) {
            this.titleTarget.addEventListener('input', () => this.fieldChanged())
        }

        if (this.hasExcerptTarget) {
            this.excerptTarget.addEventListener('input', () => this.fieldChanged())
        }
    }

    // Rich text content changed handler
    richTextChanged() {
        this.updateStats()
        this.scheduleAutosave()
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
        const data = {
            title: this.hasTitleTarget ? this.titleTarget.value : '',
            excerpt: this.hasExcerptTarget ? this.excerptTarget.value : '',
            editor_mode: this.editorModeValue
        }

        if (this.editorModeValue === 'markdown' && this.hasContentTarget) {
            data.content = this.contentTarget.value
        } else if (this.editorModeValue === 'rich_text' && this.hasRichTextContentTarget) {
            // Get HTML content from Trix editor
            const trixEditor = this.richTextContentTarget.editor
            if (trixEditor) {
                data.content_html = trixEditor.getDocument().toString()
            }
        }

        return data
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

    // Insert markdown formatting (Markdown mode only)
    insertMarkdown(event) {
        // Only allow markdown insertion in markdown mode
        if (this.editorModeValue !== 'markdown') {
            return
        }

        const button = event.currentTarget
        const format = button.dataset.format

        this.insertTextAtCursor(format)
    }

    // Insert text at cursor position (Markdown mode only)
    insertTextAtCursor(text) {
        if (!this.hasContentTarget) return

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

    // Handle keyboard shortcuts (Markdown mode only)
    keydown(event) {
        // Only process shortcuts in markdown mode
        if (this.editorModeValue !== 'markdown') {
            return
        }

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
