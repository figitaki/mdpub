import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"

// -- Hooks --

let Hooks = {}

// Theme toggle - persists preference to localStorage
Hooks.ThemeToggle = {
  mounted() {
    this.el.addEventListener("click", () => {
      const html = document.documentElement
      const current = html.getAttribute("data-theme") || getPreferredTheme()
      setTheme(current === "dark" ? "light" : "dark")
    })
  }
}

// Content page hook - sets up code block copy buttons and mermaid diagrams
// after LiveView patches the DOM
Hooks.ContentPage = {
  mounted() {
    this.setupCodeBlocks()
    this.initMermaid()
  },
  updated() {
    this.setupCodeBlocks()
    this.initMermaid()
  },
  setupCodeBlocks() {
    this.el.querySelectorAll("pre").forEach(pre => {
      if (pre.dataset.copySetup) return
      pre.dataset.copySetup = "true"

      const code = pre.querySelector("code")
      if (!code) return
      // Skip mermaid diagrams
      if (code.classList.contains("mermaid")) return

      // Wrap in container
      const wrapper = document.createElement("div")
      wrapper.className = "code-block"
      pre.parentNode.insertBefore(wrapper, pre)
      wrapper.appendChild(pre)

      // Add copy button
      const button = document.createElement("button")
      button.className = "code-block__copy"
      button.type = "button"
      button.title = "Copy code"
      button.setAttribute("aria-label", "Copy code to clipboard")
      button.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>'

      button.addEventListener("click", () => {
        const text = code.textContent
        navigator.clipboard.writeText(text).then(() => {
          button.classList.add("code-block__copy--copied")
          button.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>'
          setTimeout(() => {
            button.classList.remove("code-block__copy--copied")
            button.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>'
          }, 2000)
        }).catch(err => {
          console.error("Failed to copy:", err)
        })
      })

      wrapper.appendChild(button)

      // Add language label if present
      const langClass = Array.from(code.classList).find(c => c.startsWith("language-"))
      if (langClass) {
        const lang = langClass.replace("language-", "")
        const label = document.createElement("span")
        label.className = "code-block__lang"
        label.textContent = lang
        wrapper.appendChild(label)
      }
    })
  },
  initMermaid() {
    if (window.mermaid) {
      const nodes = this.el.querySelectorAll("code.mermaid")
      if (nodes.length > 0) {
        mermaid.run({nodes: nodes})
      }
    }
  }
}

// -- Theme management --

function getPreferredTheme() {
  const saved = localStorage.getItem("theme")
  if (saved) return saved
  return "dark"
}

function setTheme(theme) {
  document.documentElement.setAttribute("data-theme", theme)
  localStorage.setItem("theme", theme)
}

// Initialize theme immediately
setTheme(getPreferredTheme())

// Default is fixed to dark (Atom One Dark-inspired) unless user toggles manually.

// Initialize mermaid when its script loads
const mermaidScript = document.querySelector('script[src*="mermaid"]')
if (mermaidScript) {
  mermaidScript.onload = () => {
    if (window.mermaid) {
      mermaid.initialize({startOnLoad: true, securityLevel: "strict"})
    }
  }
}

// -- LiveView socket --

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
  longPollFallbackMs: 2500
})

liveSocket.connect()

window.liveSocket = liveSocket
