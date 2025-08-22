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

// Configure marked with simple syntax highlighting for better fallback support
marked.setOptions({
    highlight: function (code, language) {
        return simpleSyntaxHighlight(code, language)
    },
    breaks: true,
    gfm: true
});

export default class extends Controller {
    static values = { content: String }

    connect() {
        this.renderContent()
        this.setupScrollSpy()
    }

    contentValueChanged() {
        this.renderContent()
    }

    renderContent() {
        if (this.contentValue) {
            // Render markdown content
            const html = marked.parse(this.contentValue)
            this.element.innerHTML = html

            // Add copy functionality to code blocks
            this.addCopyButtons()

            // Add anchor links to headers
            this.addHeaderAnchors()

            // Apply syntax highlighting to any remaining code blocks
            this.element.querySelectorAll('pre code').forEach((block) => {
                // Since we're using marked's built-in highlighting, this is already done
                // Just ensure proper styling is applied
                block.parentElement.classList.add('highlight')
            })
        }
    }

    addCopyButtons() {
        this.element.querySelectorAll('pre').forEach((pre) => {
            // Skip if already has a copy button
            if (pre.querySelector('.copy-button')) return

            const code = pre.querySelector('code')
            if (!code) return

            // Create copy button
            const copyButton = document.createElement('button')
            copyButton.className = 'copy-button absolute top-2 right-2 px-3 py-1 text-xs bg-gray-700 hover:bg-gray-600 text-gray-300 hover:text-white rounded transition-colors opacity-0 group-hover:opacity-100'
            copyButton.textContent = 'Copy'
            copyButton.title = 'Copy code to clipboard'

            // Add click handler
            copyButton.addEventListener('click', async () => {
                try {
                    await navigator.clipboard.writeText(code.textContent)
                    copyButton.textContent = 'Copied!'
                    copyButton.className = copyButton.className.replace('bg-gray-700', 'bg-green-600')

                    setTimeout(() => {
                        copyButton.textContent = 'Copy'
                        copyButton.className = copyButton.className.replace('bg-green-600', 'bg-gray-700')
                    }, 2000)
                } catch (err) {
                    console.error('Failed to copy code:', err)
                    copyButton.textContent = 'Failed'
                    setTimeout(() => {
                        copyButton.textContent = 'Copy'
                    }, 2000)
                }
            })

            // Make pre element relative and add group class for hover effects
            pre.style.position = 'relative'
            pre.classList.add('group')
            pre.appendChild(copyButton)
        })
    }

    addHeaderAnchors() {
        this.element.querySelectorAll('h1, h2, h3, h4, h5, h6').forEach((header) => {
            if (header.id) {
                // Make the entire header clickable for anchor linking
                header.style.cursor = 'pointer'
                header.addEventListener('click', () => {
                    window.location.hash = `#${header.id}`

                    // Smooth scroll to the header
                    header.scrollIntoView({ behavior: 'smooth', block: 'start' })
                })

                // Add hover effect to show it's clickable
                header.addEventListener('mouseenter', () => {
                    header.style.color = '#3b82f6' // blue-500
                })

                header.addEventListener('mouseleave', () => {
                    header.style.color = '' // reset to default
                })
            }
        })
    }

    setupScrollSpy() {
        // Update table of contents based on scroll position
        const tocLinks = document.querySelectorAll('.toc-link')
        if (tocLinks.length === 0) return

        const headers = this.element.querySelectorAll('h1, h2, h3, h4, h5, h6')
        if (headers.length === 0) return

        const observer = new IntersectionObserver((entries) => {
            entries.forEach((entry) => {
                const id = entry.target.id
                const tocLink = document.querySelector(`.toc-link[href="#${id}"]`)

                if (tocLink) {
                    if (entry.isIntersecting) {
                        // Remove active class from all toc links
                        tocLinks.forEach(link => {
                            link.classList.remove('text-blue-600', 'dark:text-blue-400', 'font-medium')
                            link.classList.add('text-gray-600', 'dark:text-gray-400')
                        })

                        // Add active class to current toc link
                        tocLink.classList.remove('text-gray-600', 'dark:text-gray-400')
                        tocLink.classList.add('text-blue-600', 'dark:text-blue-400', 'font-medium')
                    }
                }
            })
        }, {
            threshold: 0.1,
            rootMargin: '-100px 0px -80% 0px'
        })

        headers.forEach((header) => {
            if (header.id) {
                observer.observe(header)
            }
        })
    }
}
