import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "skillsList", "hiddenField"]
    static values = { initial: String }

    connect() {
        this.skills = []
        this.loadInitialSkills()
        this.updateDisplay()
    }

    loadInitialSkills() {
        if (this.initialValue) {
            this.skills = this.initialValue.split(',').map(skill => skill.trim()).filter(skill => skill !== '')
        }
    }

    handleKeydown(event) {
        if (event.key === 'Enter' || event.key === ',') {
            event.preventDefault()
            this.addSkill()
        }
    }

    handleBlur() {
        this.addSkill()
    }

    addSkill() {
        const input = this.inputTarget
        const skillText = input.value.trim()

        if (skillText === '') return

        // Handle multiple skills separated by commas
        const newSkills = skillText.split(',').map(s => s.trim()).filter(s => s !== '')

        newSkills.forEach(skill => {
            if (!this.skills.includes(skill) && this.skills.length < 20) {
                this.skills.push(skill)
            }
        })

        input.value = ''
        this.updateDisplay()
        this.updateHiddenField()
        this.dispatchUpdateEvent()
    }

    removeSkill(event) {
        const skillToRemove = event.target.closest('[data-skill]').dataset.skill
        this.skills = this.skills.filter(skill => skill !== skillToRemove)
        this.updateDisplay()
        this.updateHiddenField()
        this.dispatchUpdateEvent()
    }

    updateDisplay() {
        const skillsHTML = this.skills.map(skill => `
      <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-200" data-skill="${skill}">
        ${skill}
        <button type="button" 
                class="ml-2 inline-flex items-center justify-center w-4 h-4 rounded-full text-primary-600 hover:bg-primary-200 hover:text-primary-800 dark:text-primary-400 dark:hover:bg-primary-800 dark:hover:text-primary-200"
                data-action="click->admin-skills-input#removeSkill">
          <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </span>
    `).join('')

        this.skillsListTarget.innerHTML = skillsHTML
    }

    updateHiddenField() {
        this.hiddenFieldTarget.value = this.skills.join(',')
    }

    dispatchUpdateEvent() {
        // Dispatch a custom event to trigger the preview update
        const event = new CustomEvent('skills-updated', {
            detail: { skills: this.skills },
            bubbles: true
        })
        this.element.dispatchEvent(event)
    }
}
