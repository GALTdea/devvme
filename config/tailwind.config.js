module.exports = {
    content: [
        './app/views/**/*.erb',
        './app/helpers/**/*.rb',
        './app/assets/stylesheets/**/*.css',
        './app/javascript/**/*.js'
    ],
    darkMode: 'class', // Use class strategy instead of media query
    theme: {
        extend: {},
    },
    plugins: [],
}
