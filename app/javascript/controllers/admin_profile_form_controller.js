import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["preview"]

    connect() {
        this.updatePreview()
        // Listen for skills updates
        this.element.addEventListener('skills-updated', () => {
            this.updatePreview()
        })
    }

    updatePreview() {
        const formData = new FormData(this.element)
        const username = formData.get("user[username]") || ""
        const fullName = formData.get("user[full_name]") || ""
        const email = formData.get("user[email]") || ""
        const jobTitle = formData.get("user[job_title]") || ""
        const location = formData.get("user[location]") || ""
        const headline = formData.get("user[headline]") || ""
        const bio = formData.get("user[bio]") || ""
        const skills = formData.get("user[skills]") || ""
        const role = formData.get("user[role]") || "user"

        // Calculate completion percentage
        const fields = [username, fullName, email, jobTitle, location, headline, bio, skills]
        const completedFields = fields.filter(field => field.trim() !== "").length
        const completionPercentage = Math.round((completedFields / fields.length) * 100)

        // Generate avatar initials
        const initials = fullName ? fullName.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2) :
            username ? username[0].toUpperCase() : '?'

        // Parse skills
        const skillsArray = skills ? skills.split(',').filter(s => s.trim() !== '') : []

        // Generate preview HTML
        const previewHTML = `
      <div class="text-center">
        <!-- Avatar -->
        <div class="h-16 w-16 bg-primary-600 rounded-full mx-auto mb-4 flex items-center justify-center">
          <span class="text-white text-xl font-medium">${initials}</span>
        </div>
        
        <!-- Name and Username -->
        <div class="mb-4">
          <h3 class="text-lg font-medium text-secondary-900 dark:text-white">
            ${fullName || 'Full Name'}
          </h3>
          <p class="text-sm text-secondary-600 dark:text-secondary-400">
            @${username || 'username'}
          </p>
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium mt-2 ${this.getRoleBadgeClass(role)}">
            ${role.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
          </span>
        </div>

        <!-- Professional Info -->
        ${jobTitle || location ? `
          <div class="mb-4 text-sm text-secondary-700 dark:text-secondary-300">
            ${jobTitle ? `<div class="font-medium">${jobTitle}</div>` : ''}
            ${location ? `<div class="text-secondary-500 dark:text-secondary-400">${location}</div>` : ''}
          </div>
        ` : ''}

        <!-- Headline -->
        ${headline ? `
          <div class="mb-4">
            <p class="text-sm text-secondary-600 dark:text-secondary-400 italic">
              "${headline}"
            </p>
          </div>
        ` : ''}

        <!-- Bio Preview -->
        ${bio ? `
          <div class="mb-4">
            <p class="text-xs text-secondary-600 dark:text-secondary-400 text-left">
              ${bio.length > 100 ? bio.substring(0, 100) + '...' : bio}
            </p>
          </div>
        ` : ''}

        <!-- Skills Preview -->
        ${skillsArray.length > 0 ? `
          <div class="mb-4">
            <div class="flex flex-wrap gap-1 justify-center">
              ${skillsArray.slice(0, 6).map(skill => `
                <span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-200">
                  ${skill.trim()}
                </span>
              `).join('')}
              ${skillsArray.length > 6 ? `
                <span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-secondary-100 text-secondary-800 dark:bg-secondary-700 dark:text-secondary-200">
                  +${skillsArray.length - 6} more
                </span>
              ` : ''}
            </div>
          </div>
        ` : ''}

        <!-- Completion Status -->
        <div class="mt-6 pt-4 border-t border-secondary-200 dark:border-secondary-700">
          <div class="flex items-center justify-between text-sm">
            <span class="text-secondary-600 dark:text-secondary-400">Profile Completion</span>
            <span class="font-medium text-secondary-900 dark:text-white">${completionPercentage}%</span>
          </div>
          <div class="mt-2 bg-secondary-200 dark:bg-secondary-600 rounded-full h-2">
            <div class="bg-primary-600 h-2 rounded-full transition-all duration-300" style="width: ${completionPercentage}%"></div>
          </div>
          <p class="mt-2 text-xs text-secondary-500 dark:text-secondary-400">
            ${completionPercentage >= 80 ? '🎉 Excellent! This profile will make a great impression.' :
                completionPercentage >= 60 ? '👍 Good profile! Consider adding more details.' :
                    completionPercentage >= 40 ? '📝 Getting there! Add more information for better results.' :
                        '🚀 Just getting started! Fill in more fields for a complete profile.'}
          </p>
        </div>

        <!-- Invitation Status -->
        <div class="mt-4 p-3 bg-amber-50 dark:bg-amber-900/20 rounded-lg border border-amber-200 dark:border-amber-800">
          <div class="flex items-center justify-center text-amber-800 dark:text-amber-200">
            <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 4.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
            <span class="text-sm font-medium">Will be sent invitation</span>
          </div>
          <p class="text-xs text-amber-700 dark:text-amber-300 mt-1 text-center">
            ${email || 'Email address required'}
          </p>
        </div>
      </div>
    `

        this.previewTarget.innerHTML = previewHTML
    }

    getRoleBadgeClass(role) {
        switch (role) {
            case 'super_admin':
                return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
            case 'admin':
                return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200'
            default:
                return 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200'
        }
    }
}
