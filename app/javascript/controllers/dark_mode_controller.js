import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dark-mode"
export default class extends Controller {
    static targets = ["toggle"]

    connect() {
        // Check for saved theme preference or default to 'light'
        const savedTheme = localStorage.getItem('theme')
        const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
        // console.log("Dark mode controller connected ")

        if (savedTheme === 'dark' || (!savedTheme && systemPrefersDark)) {
            this.enableDarkMode()
        } else {
            this.disableDarkMode()
        }

        // Listen for system theme changes
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
            if (!localStorage.getItem('theme')) {
                if (e.matches) {
                    this.enableDarkMode()
                } else {
                    this.disableDarkMode()
                }
            }
        })
    }

    toggle() {
        const currentMode = document.documentElement.classList.contains('dark') ? 'dark' : 'light'
        // console.log(`Dark mode toggle clicked. Current mode: ${currentMode}`)

        if (document.documentElement.classList.contains('dark')) {
            this.disableDarkMode()
            localStorage.setItem('theme', 'light')
            // console.log('Switching to light mode')
        } else {
            this.enableDarkMode()
            localStorage.setItem('theme', 'dark')
            // console.log('Switching to dark mode')
        }
    }

    enableDarkMode() {
        document.documentElement.classList.add('dark')
        this.updateToggleButton(true)
    }

    disableDarkMode() {
        document.documentElement.classList.remove('dark')
        this.updateToggleButton(false)
    }

    updateToggleButton(isDark) {
        if (this.hasToggleTarget) {
            const icon = this.toggleTarget.querySelector('svg')
            const text = this.toggleTarget.querySelector('span')

            if (isDark) {
                // Show sun icon for light mode option
                icon.innerHTML = `
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
        `
                if (text) text.textContent = 'Light Mode'
            } else {
                // Show moon icon for dark mode option
                icon.innerHTML = `
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
        `
                if (text) text.textContent = 'Dark Mode'
            }
        }
    }
}
