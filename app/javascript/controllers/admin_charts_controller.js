import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="admin-charts"
export default class extends Controller {
    static targets = ["registrationChart", "activityChart", "contentChart", "onlineUsers"]
    static values = {
        registrationData: Object,
        activityData: Object,
        contentData: Array,
        onlineUsersUrl: String
    }

    connect() {
        // Wait for DOM to be fully ready
        this.initializeCharts()
        this.startOnlineUsersUpdates()
    }

    disconnect() {
        this.stopOnlineUsersUpdates()
    }

    initializeCharts() {
        // Add a small delay to ensure DOM is fully ready
        setTimeout(() => {
            this.createCharts()
        }, 100)
    }

    createCharts() {
        if (this.hasRegistrationChartTarget) {
            this.createRegistrationChart()
        }

        if (this.hasActivityChartTarget) {
            this.createActivityChart()
        }

        if (this.hasContentChartTarget) {
            this.createContentChart()
        }
    }

    createRegistrationChart() {
        const ctx = this.registrationChartTarget.getContext('2d')
        const data = this.registrationDataValue

        new Chart(ctx, {
            type: 'line',
            data: {
                labels: Object.keys(data).map(date => new Date(date).toLocaleDateString()),
                datasets: [{
                    label: 'New Registrations',
                    data: Object.values(data),
                    borderColor: 'rgb(59, 130, 246)',
                    backgroundColor: 'rgba(59, 130, 246, 0.1)',
                    tension: 0.4
                }]
            },
            options: this.getChartOptions()
        })
    }

    createActivityChart() {
        const ctx = this.activityChartTarget.getContext('2d')
        const data = this.activityDataValue

        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: Object.keys(data).map(date => new Date(date).toLocaleDateString()),
                datasets: [{
                    label: 'Admin Actions',
                    data: Object.values(data),
                    backgroundColor: 'rgba(16, 185, 129, 0.8)',
                    borderColor: 'rgb(16, 185, 129)',
                    borderWidth: 1
                }]
            },
            options: this.getChartOptions()
        })
    }

    createContentChart() {
        const ctx = this.contentChartTarget.getContext('2d')
        const data = this.contentDataValue

        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: data.map(item => new Date(item.date).toLocaleDateString()),
                datasets: [
                    {
                        label: 'Blog Posts',
                        data: data.map(item => item.blog_posts),
                        backgroundColor: 'rgba(99, 102, 241, 0.8)',
                        borderColor: 'rgb(99, 102, 241)',
                        borderWidth: 1
                    },
                    {
                        label: 'Projects',
                        data: data.map(item => item.projects),
                        backgroundColor: 'rgba(168, 85, 247, 0.8)',
                        borderColor: 'rgb(168, 85, 247)',
                        borderWidth: 1
                    }
                ]
            },
            options: this.getChartOptions()
        })
    }

    getChartOptions() {
        const isDarkMode = document.documentElement.classList.contains('dark')

        return {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    labels: {
                        color: isDarkMode ? '#e5e7eb' : '#374151'
                    }
                }
            },
            scales: {
                x: {
                    ticks: {
                        color: isDarkMode ? '#9ca3af' : '#6b7280'
                    },
                    grid: {
                        color: isDarkMode ? '#374151' : '#e5e7eb'
                    }
                },
                y: {
                    ticks: {
                        color: isDarkMode ? '#9ca3af' : '#6b7280'
                    },
                    grid: {
                        color: isDarkMode ? '#374151' : '#e5e7eb'
                    }
                }
            }
        }
    }

    startOnlineUsersUpdates() {
        if (this.hasOnlineUsersTarget && this.onlineUsersUrlValue) {
            this.updateOnlineUsers()
            this.onlineUsersInterval = setInterval(() => {
                this.updateOnlineUsers()
            }, 30000) // Update every 30 seconds
        }
    }

    stopOnlineUsersUpdates() {
        if (this.onlineUsersInterval) {
            clearInterval(this.onlineUsersInterval)
        }
    }

    updateOnlineUsers() {
        fetch(this.onlineUsersUrlValue, {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            }
        })
            .then(response => response.json())
            .then(data => {
                this.onlineUsersTarget.textContent = data.count
            })
            .catch(error => console.log('Error updating online users:', error))
    }
}
