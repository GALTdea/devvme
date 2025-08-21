import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"
import hljs from "highlight.js"

// Configure marked with syntax highlighting
marked.setOptions({
    highlight: function (code, language) {
        if (language && hljs.getLanguage(language)) {
            try {
                return hljs.highlight(code, { language: language }).value;
            } catch (e) {
                console.error('Syntax highlighting error:', e);
            }
        }
        return hljs.highlightAuto(code).value;
    },
    breaks: true,
    gfm: true
});

export default class extends Controller {
    static values = { content: String }

    connect() {
        this.renderContent()
    }

    contentValueChanged() {
        this.renderContent()
    }

    renderContent() {
        if (this.contentValue) {
            const html = marked.parse(this.contentValue)
            this.element.innerHTML = html
        }
    }
}
