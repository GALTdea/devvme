import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["uniqueVisitors", "totalVisitors", "conversionRate", "returningVisitors"]
    static values = {
        updateUrl: String,
        timeRange: String,
        updateInterval: { type: Number, default: 60000 } // 60 seconds
    }

    connect() {
        console.log("Visitor Analytics controller connected")
        this.startPolling()
    }

    disconnect() {
        console.log("Visitor Analytics controller disconnected")
        this.stopPolling()
    }

    startPolling() {
        // Update immediately
        this.updateMetrics()

        // Set up periodic updates
        this.pollTimer = setInterval(() => {
            this.updateMetrics()
        }, this.updateIntervalValue)
    }

    stopPolling() {
        if (this.pollTimer) {
            clearInterval(this.pollTimer)
            this.pollTimer = null
        }
    }

    async updateMetrics() {
        try {
            const url = new URL(this.updateUrlValue, window.location.origin)
            url.searchParams.set('time_range', this.timeRangeValue)

            const response = await fetch(url, {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
                }
            })

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`)
            }

            const data = await response.json()
            this.updateUI(data)

            // Show success indicator
            this.showUpdateIndicator(true)

        } catch (error) {
            console.error('Error updating visitor metrics:', error)
            this.showUpdateIndicator(false)
        }
    }

    updateUI(data) {
        // Update metric values with animation
        this.animateValue(this.uniqueVisitorsTarget, data.unique_visitors)
        this.animateValue(this.totalVisitorsTarget, data.total_visitors)
        this.animateValue(this.returningVisitorsTarget, data.returning_visitors)

        // Update conversion rate with percentage
        if (this.hasConversionRateTarget) {
            this.animateValue(this.conversionRateTarget, data.conversion_rate, '%')
        }
    }

    animateValue(element, newValue, suffix = '') {
        const currentValue = parseInt(element.textContent) || 0
        const targetValue = newValue || 0

        if (currentValue === targetValue) return

        const duration = 1000 // 1 second animation
        const startTime = performance.now()
        const difference = targetValue - currentValue

        const animate = (currentTime) => {
            const elapsed = currentTime - startTime
            const progress = Math.min(elapsed / duration, 1)

            // Easing function for smooth animation
            const easeOutQuart = 1 - Math.pow(1 - progress, 4)
            const currentAnimatedValue = Math.round(currentValue + (difference * easeOutQuart))

            element.textContent = currentAnimatedValue + suffix

            if (progress < 1) {
                requestAnimationFrame(animate)
            } else {
                element.textContent = targetValue + suffix
            }
        }

        requestAnimationFrame(animate)
    }

    showUpdateIndicator(success) {
        const indicator = document.querySelector('.live-indicator')
        if (!indicator) return

        const dot = indicator.querySelector('.animate-pulse')
        if (!dot) return

        // Remove existing classes
        dot.classList.remove('bg-green-500', 'bg-red-500', 'bg-yellow-500')

        if (success) {
            dot.classList.add('bg-green-500')
            // Flash effect
            dot.classList.remove('animate-pulse')
            setTimeout(() => dot.classList.add('animate-pulse'), 100)
        } else {
            dot.classList.add('bg-red-500')
        }
    }

    // Handle time range changes
    timeRangeChanged(event) {
        this.timeRangeValue = event.target.value
        // Update immediately when time range changes
        this.updateMetrics()
    }

    // Manual refresh button
    refresh() {
        this.updateMetrics()
    }

    // Pause/resume polling
    togglePolling() {
        if (this.pollTimer) {
            this.stopPolling()
            console.log("Polling paused")
        } else {
            this.startPolling()
            console.log("Polling resumed")
        }
    }
}
