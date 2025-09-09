import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chart"
export default class extends Controller {
    static targets = ["canvas"]
    static values = {
        data: Object,
        type: String,
        options: Object
    }

    connect() {
        this.loadChartJS().then(() => {
            this.createChart()
        })
    }

    async loadChartJS() {
        if (window.Chart) {
            return Promise.resolve()
        }

        return new Promise((resolve, reject) => {
            const script = document.createElement('script')
            script.src = 'https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js'
            script.onload = () => resolve()
            script.onerror = () => reject(new Error('Failed to load Chart.js'))
            document.head.appendChild(script)
        })
    }

    createChart() {
        if (!this.hasCanvasTarget) return

        const ctx = this.canvasTarget.getContext('2d')
        const rawData = this.dataValue || {}
        const type = this.typeValue || 'line'
        const options = this.getChartOptions()

        // Merge custom options if provided
        if (this.optionsValue) {
            Object.assign(options, this.optionsValue)
        }

        // Transform data based on chart type
        let chartData
        if (type === 'line') {
            chartData = this.transformLineData(rawData)
        } else if (type === 'bar') {
            chartData = this.transformBarData(rawData)
        } else if (type === 'doughnut') {
            chartData = this.transformDoughnutData(rawData)
        } else {
            chartData = rawData
        }

        new window.Chart(ctx, {
            type: type,
            data: chartData,
            options: options
        })
    }

    transformLineData(data) {
        return {
            labels: Object.keys(data).map(date => new Date(date).toLocaleDateString()),
            datasets: [{
                label: 'Data',
                data: Object.values(data),
                borderColor: 'rgb(59, 130, 246)',
                backgroundColor: 'rgba(59, 130, 246, 0.1)',
                tension: 0.4,
                fill: true
            }]
        }
    }

    transformBarData(data) {
        // Handle feature adoption data structure
        if (data.blog_adoption !== undefined) {
            return {
                labels: ['Blog Adoption', 'Project Adoption', 'Profile Completion'],
                datasets: [{
                    label: 'Adoption Rate (%)',
                    data: [
                        data.blog_adoption,
                        data.project_adoption,
                        data.profile_completion
                    ],
                    backgroundColor: [
                        'rgba(59, 130, 246, 0.8)',
                        'rgba(168, 85, 247, 0.8)',
                        'rgba(16, 185, 129, 0.8)'
                    ],
                    borderColor: [
                        'rgb(59, 130, 246)',
                        'rgb(168, 85, 247)',
                        'rgb(16, 185, 129)'
                    ],
                    borderWidth: 1
                }]
            }
        }

        // Handle hourly distribution data
        if (Array.isArray(data)) {
            return {
                labels: Array.from({ length: 24 }, (_, i) => i + ':00'),
                datasets: [{
                    label: 'Activity Level',
                    data: Array.from({ length: 24 }, (_, i) => data[i] || 0),
                    backgroundColor: 'rgba(168, 85, 247, 0.8)',
                    borderColor: 'rgb(168, 85, 247)',
                    borderWidth: 1
                }]
            }
        }

        // Default time series data
        return {
            labels: Object.keys(data).map(date => new Date(date).toLocaleDateString()),
            datasets: [{
                label: 'Data',
                data: Object.values(data),
                backgroundColor: 'rgba(16, 185, 129, 0.8)',
                borderColor: 'rgb(16, 185, 129)',
                borderWidth: 1
            }]
        }
    }

    transformDoughnutData(data) {
        // Handle different data structures for doughnut charts
        if (data.blog_views !== undefined && data.other_views !== undefined) {
            return {
                labels: ['Blog Content', 'Other Content'],
                datasets: [{
                    data: [data.blog_views, data.other_views],
                    backgroundColor: [
                        'rgba(37, 99, 235, 0.8)',
                        'rgba(107, 114, 128, 0.8)'
                    ],
                    borderColor: [
                        'rgb(37, 99, 235)',
                        'rgb(107, 114, 128)'
                    ],
                    borderWidth: 1
                }]
            }
        }

        // Handle feature usage data structure
        if (data.blog_posts_created !== undefined) {
            return {
                labels: ['Blog Posts', 'Projects', 'Profile Views'],
                datasets: [{
                    data: [
                        data.blog_posts_created,
                        data.projects_created,
                        data.profile_views
                    ],
                    backgroundColor: [
                        'rgba(59, 130, 246, 0.8)',
                        'rgba(168, 85, 247, 0.8)',
                        'rgba(16, 185, 129, 0.8)'
                    ],
                    borderColor: [
                        'rgb(59, 130, 246)',
                        'rgb(168, 85, 247)',
                        'rgb(16, 185, 129)'
                    ],
                    borderWidth: 1
                }]
            }
        }

        // Fallback for other data structures
        return {
            labels: Object.keys(data),
            datasets: [{
                data: Object.values(data),
                backgroundColor: [
                    'rgba(37, 99, 235, 0.8)',
                    'rgba(107, 114, 128, 0.8)',
                    'rgba(16, 185, 129, 0.8)',
                    'rgba(245, 158, 11, 0.8)',
                    'rgba(239, 68, 68, 0.8)'
                ],
                borderWidth: 1
            }]
        }
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
}
