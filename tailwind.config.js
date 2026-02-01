/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./lib/**/*.ex",
    "./priv/static/**/*.html"
  ],
  theme: {
    extend: {
      colors: {
        bg: '#0b0f19',
        panel: '#111827',
        muted: '#9ca3af',
        link: '#93c5fd',
        border: 'rgba(255,255,255,0.08)',
        'code-bg': 'rgba(255,255,255,0.06)',
      },
      maxWidth: {
        'prose': '880px',
      },
    },
  },
  plugins: [],
}
