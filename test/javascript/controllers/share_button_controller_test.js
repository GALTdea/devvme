// JavaScript unit tests for share_button_controller
// Note: This would require setting up a JavaScript testing framework like Jest or Vitest

import { Application } from "@hotwired/stimulus"
import ShareButtonController from "../../../app/javascript/controllers/share_button_controller"

// Mock DOM environment
const { JSDOM } = require('jsdom')
const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>')
global.document = dom.window.document
global.window = dom.window
global.navigator = dom.window.navigator

describe("ShareButtonController", () => {
    let application
    let controller
    let element

    beforeEach(() => {
        application = Application.start()
        application.register("share-button", ShareButtonController)

        // Create test element
        element = document.createElement('div')
        element.setAttribute('data-controller', 'share-button')
        element.setAttribute('data-share-button-url-value', 'https://example.com/profile')
        element.setAttribute('data-share-button-title-value', 'Test User Profile')

        const button = document.createElement('button')
        button.setAttribute('data-action', 'click->share-button#share')
        element.appendChild(button)

        document.body.appendChild(element)

        controller = application.getControllerForElementAndIdentifier(element, 'share-button')
    })

    afterEach(() => {
        document.body.innerHTML = ''
    })

    describe("#share", () => {
        it("uses Web Share API when available", async () => {
            const shareData = {}
            global.navigator.share = jest.fn().mockResolvedValue()

            const event = { preventDefault: jest.fn() }
            await controller.share(event)

            expect(event.preventDefault).toHaveBeenCalled()
            expect(global.navigator.share).toHaveBeenCalledWith({
                title: 'Test User Profile',
                url: 'https://example.com/profile'
            })
        })

        it("falls back to clipboard when Web Share API unavailable", async () => {
            global.navigator.share = undefined
            global.navigator.clipboard = {
                writeText: jest.fn().mockResolvedValue()
            }

            const event = { preventDefault: jest.fn() }
            await controller.share(event)

            expect(global.navigator.clipboard.writeText).toHaveBeenCalledWith('https://example.com/profile')
        })

        it("falls back to clipboard when Web Share API rejects", async () => {
            global.navigator.share = jest.fn().mockRejectedValue(new Error('Cancelled'))
            global.navigator.clipboard = {
                writeText: jest.fn().mockResolvedValue()
            }

            const event = { preventDefault: jest.fn() }
            await controller.share(event)

            expect(global.navigator.clipboard.writeText).toHaveBeenCalledWith('https://example.com/profile')
        })
    })

    describe("#fallbackShare", () => {
        it("copies URL to clipboard", async () => {
            global.navigator.clipboard = {
                writeText: jest.fn().mockResolvedValue()
            }

            controller.fallbackShare('https://example.com/test')

            expect(global.navigator.clipboard.writeText).toHaveBeenCalledWith('https://example.com/test')
        })

        it("shows success notification on successful copy", async () => {
            global.navigator.clipboard = {
                writeText: jest.fn().mockResolvedValue()
            }

            jest.spyOn(controller, 'showNotification')

            await controller.fallbackShare('https://example.com/test')

            expect(controller.showNotification).toHaveBeenCalledWith('Profile URL copied to clipboard!')
        })

        it("shows error notification on copy failure", async () => {
            global.navigator.clipboard = {
                writeText: jest.fn().mockRejectedValue(new Error('Permission denied'))
            }

            jest.spyOn(controller, 'showNotification')

            await controller.fallbackShare('https://example.com/test')

            expect(controller.showNotification).toHaveBeenCalledWith('Failed to copy URL', 'error')
        })
    })

    describe("#showNotification", () => {
        it("creates and displays notification element", () => {
            controller.showNotification('Test message')

            const notification = document.querySelector('.fixed.top-4.right-4')
            expect(notification).toBeTruthy()
            expect(notification.textContent).toBe('Test message')
            expect(notification.classList.contains('bg-green-500')).toBe(true)
        })

        it("creates error notification with red background", () => {
            controller.showNotification('Error message', 'error')

            const notification = document.querySelector('.fixed.top-4.right-4')
            expect(notification.classList.contains('bg-red-500')).toBe(true)
        })

        it("removes notification after timeout", (done) => {
            controller.showNotification('Test message')

            // Override setTimeout to control timing in tests
            const originalSetTimeout = global.setTimeout
            global.setTimeout = (callback, delay) => {
                if (delay === 3000) {
                    // Fast-forward to when notification should fade
                    callback()
                    // Fast-forward to when notification should be removed
                    global.setTimeout = originalSetTimeout
                    setTimeout(() => {
                        const notification = document.querySelector('.fixed.top-4.right-4')
                        expect(notification).toBeFalsy()
                        done()
                    }, 350) // After fade transition
                }
            }
        })
    })
})

// Export for potential use in other tests
export { ShareButtonController }
