import { Controller } from "@hotwired/stimulus"

// Chat UI: auto-scroll to bottom on new messages and when thinking indicator appears;
// clear input and show thinking state after user submit.
export default class extends Controller {
  static targets = ["messageList", "thinkingIndicator", "form", "input", "submitButton"]
  static values = { thinking: String }

  connect() {
    this.scrollToBottom()
    this.observeMessageList()
  }

  disconnect() {
    if (this._resizeObserver) this._resizeObserver.disconnect()
    if (this._mutationObserver) this._mutationObserver.disconnect()
  }

  // After form submit (Turbo Stream response): scroll to bottom, show thinking, clear input.
  afterSubmit(event) {
    if (event.detail.success !== false) {
      this.clearInput()
      this.scrollToBottom()
      requestAnimationFrame(() => this.scrollToBottom())
    }
  }

  // Scroll the message list to the bottom.
  scrollToBottom() {
    if (!this.hasMessageListTarget) return
    const el = this.messageListTarget
    el.scrollTop = el.scrollHeight
  }

  // Observe new content (Turbo Stream appends) and scroll into view.
  observeMessageList() {
    if (!this.hasMessageListTarget) return
    this._resizeObserver = new ResizeObserver(() => this.scrollToBottom())
    this._resizeObserver.observe(this.messageListTarget)
    const observer = new MutationObserver(() => this.scrollToBottom())
    observer.observe(this.messageListTarget, { childList: true, subtree: true })
    this._mutationObserver = observer
  }

  clearInput() {
    if (this.hasInputTarget) this.inputTarget.value = ""
  }
}
