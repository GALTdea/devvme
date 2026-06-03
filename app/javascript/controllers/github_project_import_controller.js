import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "notice", "error", "pickerToggle", "pickerPanel", "searchInput", "includeForks",
        "repoLoading", "repoEmpty", "repoList", "urlInput", "importButton"
    ]
    static values = {
        repositoriesUrl: String,
        prefillUrl: String,
        connected: Boolean,
        formSelector: { type: String, default: "#project_form" }
    }

    connect() {
        this.repositories = []
        this.pickerOpen = false
    }

    togglePicker() {
        this.pickerOpen = !this.pickerOpen
        this.pickerPanelTarget.classList.toggle("hidden", !this.pickerOpen)
        if (this.pickerOpen && this.connectedValue && this.repositories.length === 0) {
            this.reloadRepositories()
        }
    }

    async reloadRepositories() {
        if (!this.connectedValue) return

        this.showRepoLoading(true)
        this.clearError()

        const url = new URL(this.repositoriesUrlValue, window.location.origin)
        if (this.hasIncludeForksTarget && this.includeForksTarget.checked) {
            url.searchParams.set("include_forks", "1")
        }

        try {
            const response = await this.fetchJson(url.toString())
            this.repositories = response.repositories || []
            this.renderRepositories()
        } catch (error) {
            this.showError(error.message)
            this.repositories = []
            this.renderRepositories()
        } finally {
            this.showRepoLoading(false)
        }
    }

    filterRepositories() {
        this.renderRepositories()
    }

    renderRepositories() {
        const query = this.hasSearchInputTarget ? this.searchInputTarget.value.trim().toLowerCase() : ""
        const filtered = this.repositories.filter((repo) => {
            if (!query) return true
            const haystack = [repo.full_name, repo.description, repo.language].filter(Boolean).join(" ").toLowerCase()
            return haystack.includes(query)
        })

        this.repoListTarget.innerHTML = ""
        this.repoEmptyTarget.classList.toggle("hidden", filtered.length > 0)

        filtered.forEach((repo) => {
            const item = document.createElement("li")
            item.className = "p-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between"
            item.innerHTML = `
                <div>
                  <p class="text-sm font-medium text-gray-900">${this.escapeHtml(repo.full_name)}</p>
                  <p class="text-xs text-gray-500 mt-0.5">
                    ${repo.private ? "Private" : "Public"}
                    ${repo.archived ? " · Archived" : ""}
                    ${repo.language ? ` · ${this.escapeHtml(repo.language)}` : ""}
                    ${repo.pushed_at ? ` · Pushed ${this.escapeHtml(this.formatDate(repo.pushed_at))}` : ""}
                  </p>
                  ${repo.description ? `<p class="text-xs text-gray-600 mt-1">${this.escapeHtml(repo.description)}</p>` : ""}
                </div>
                <button type="button" class="text-sm font-medium text-blue-600 hover:text-blue-800 shrink-0">Import</button>
            `
            item.querySelector("button").addEventListener("click", () => this.importRepository(repo.url))
            this.repoListTarget.appendChild(item)
        })
    }

    importFromUrl() {
        const url = this.urlInputTarget.value.trim()
        if (!url) {
            this.showError("Enter a GitHub repository URL.")
            return
        }
        this.importRepository(url)
    }

    async importRepository(repositoryUrl) {
        this.setImporting(true)
        this.clearError()
        this.clearNotice()

        try {
            const response = await this.fetchJson(this.prefillUrlValue, {
                method: "POST",
                body: JSON.stringify({ repository_url: repositoryUrl })
            })
            const summary = this.applyPrefill(response)
            this.showNotice(summary)
            if (this.hasUrlInputTarget) {
                this.urlInputTarget.value = response.repository?.canonical_url || repositoryUrl
            }
        } catch (error) {
            this.showError(error.message)
        } finally {
            this.setImporting(false)
        }
    }

    applyPrefill(payload) {
        const form = document.querySelector(this.formSelectorValue)
        if (!form) return { filled: [], skipped: [] }

        const filled = []
        const skipped = []

        const project = payload.project || {}
        this.applyTextField(form, "project[title]", project.title, "title", filled, skipped)
        this.applyTextField(form, "project[description]", project.description, "description", filled, skipped)
        this.applyTextField(form, "project[source_code_url]", project.source_code_url, "source code URL", filled, skipped)
        this.applyTextField(form, "project[live_url]", project.live_url, "live URL", filled, skipped)

        if (project.technologies_display) {
            if (this.isFieldEmpty(form, "project[technologies_display]")) {
                this.applyTechnologies(project.technologies_display)
                filled.push("technologies")
            } else {
                skipped.push("technologies")
            }
        }

        const story = payload.project_story || {}
        Object.entries(story).forEach(([field, value]) => {
            this.applyTextField(form, `project[project_story][${field}]`, value, `story ${field}`, filled, skipped)
        })

        if (project.project_insight_enabled === true) {
            this.applyCheckbox(form, "project[project_insight_enabled]", "Project Insight", filled, skipped)
        }

        if (project.github_insights_enabled === true) {
            this.applyCheckbox(form, "project[github_insights_enabled]", "GitHub enrichment", filled, skipped)
        }

        return { filled, skipped }
    }

    applyTextField(form, name, value, label, filled, skipped) {
        if (!value) return
        const field = form.querySelector(`[name="${name}"]`)
        if (!field) return

        if (this.isInputEmpty(field)) {
            field.value = value
            field.dispatchEvent(new Event("input", { bubbles: true }))
            filled.push(label)
        } else {
            skipped.push(label)
        }
    }

    applyCheckbox(form, name, label, filled, skipped) {
        const field = form.querySelector(`[name="${name}"]`)
        if (!field || field.type !== "checkbox") return

        if (!field.checked) {
            field.checked = true
            filled.push(label)
        } else {
            skipped.push(label)
        }
    }

    applyTechnologies(displayValue) {
        const hidden = document.querySelector('[data-technology-tags-target="hiddenField"]')
        if (!hidden) return

        const tags = displayValue.split(",").map((tag) => tag.trim()).filter(Boolean).slice(0, 10)
        hidden.value = tags.join(", ")
        hidden.dispatchEvent(new Event("input", { bubbles: true }))

        const container = hidden.closest('[data-controller~="technology-tags"]')
        if (!container) return

        const controller = this.application.getControllerForElementAndIdentifier(container, "technology-tags")
        if (controller && typeof controller.importTechnologies === "function") {
            controller.importTechnologies(tags)
        }
    }

    isFieldEmpty(form, name) {
        const field = form.querySelector(`[name="${name}"]`)
        return !field || this.isInputEmpty(field)
    }

    isInputEmpty(field) {
        return field.value == null || field.value.toString().trim() === ""
    }

    showNotice({ filled, skipped }) {
        const parts = []
        if (filled.length > 0) {
            parts.push(`Prefilled: ${filled.join(", ")}.`)
        }
        if (skipped.length > 0) {
            parts.push(`Kept your existing ${skipped.join(", ")}.`)
        }
        if (parts.length === 0) {
            parts.push("No empty fields were available to prefill.")
        }

        this.noticeTarget.textContent = parts.join(" ")
        this.noticeTarget.className = "mt-4 rounded-md border border-green-200 bg-green-50 p-3 text-sm text-green-800"
        this.noticeTarget.classList.remove("hidden")
    }

    showError(message) {
        this.errorTarget.textContent = message
        this.errorTarget.classList.remove("hidden")
    }

    clearError() {
        this.errorTarget.textContent = ""
        this.errorTarget.classList.add("hidden")
    }

    clearNotice() {
        this.noticeTarget.textContent = ""
        this.noticeTarget.classList.add("hidden")
    }

    showRepoLoading(loading) {
        if (this.hasRepoLoadingTarget) {
            this.repoLoadingTarget.classList.toggle("hidden", !loading)
        }
    }

    setImporting(importing) {
        if (this.hasImportButtonTarget) {
            this.importButtonTarget.disabled = importing
            this.importButtonTarget.textContent = importing ? "Importing…" : "Apply prefill"
        }
    }

    async fetchJson(url, options = {}) {
        const headers = {
            Accept: "application/json",
            "Content-Type": "application/json",
            "X-CSRF-Token": this.csrfToken
        }

        const response = await fetch(url, {
            credentials: "same-origin",
            headers,
            ...options
        })

        const body = await response.json().catch(() => ({}))
        if (!response.ok) {
            throw new Error(body.error || "Import request failed.")
        }
        return body
    }

    get csrfToken() {
        return document.querySelector('meta[name="csrf-token"]')?.content
    }

    formatDate(value) {
        const date = new Date(value)
        if (Number.isNaN(date.getTime())) return value
        return date.toLocaleDateString()
    }

    escapeHtml(value) {
        return value.toString()
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
    }
}
