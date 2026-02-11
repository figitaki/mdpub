defmodule Mdpub.PageLayout do
  @moduledoc """
  HTML page layout and rendering for mdpub.

  Provides a consistent shell layout with:
  - Sticky header with branding and navigation
  - Mobile-friendly hamburger menu
  - Theme toggle (light/dark mode)
  - Breadcrumb navigation
  - Centered content area with optimal reading width
  - Document navigation (prev/next links)
  - Footer
  """

  @app_name "mdpub"

  def render(%{title: title, body_html: body_html, path: path, nav_items: nav_items}) do
    breadcrumb = build_breadcrumb(path)
    nav_links = build_doc_nav(path, nav_items)
    page(title, body_html, breadcrumb, nav_links, path, nav_items)
  end

  def render(%{title: title, body_html: body_html, path: path}) do
    breadcrumb = build_breadcrumb(path)
    page(title, body_html, breadcrumb, nil, path, [])
  end

  def render(%{title: title, body_html: body_html}) do
    page(title, body_html, nil, nil, nil, [])
  end

  def render_404(path_segments, nav_items \\ []) do
    requested = "/" <> Enum.join(path_segments, "/")

    body = """
    <h1>Page not found</h1>
    <p>We couldn't find a document at <code>#{escape(requested)}</code>.</p>
    <p><a href="#{base_path()}/">Return to home</a></p>
    """

    page("Not found", body, nil, nil, nil, nav_items)
  end

  def render_error(path_segments, reason, nav_items \\ []) do
    requested = "/" <> Enum.join(path_segments, "/")

    body = """
    <h1>Something went wrong</h1>
    <p>There was a problem rendering <code>#{escape(requested)}</code>.</p>
    <pre><code>#{escape(inspect(reason))}</code></pre>
    <p><a href="#{base_path()}/">Return to home</a></p>
    """

    page("Error", body, nil, nil, nil, nav_items)
  end

  defp page(title, body_html, breadcrumb, nav_links, current_path, nav_items) do
    base = base_path()

    """
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="color-scheme" content="light dark" />
        <title>#{escape(title)} · #{@app_name}</title>
        <base href="#{escape(base)}/" />
        <link rel="stylesheet" href="#{escape(base)}/assets/style.css" />
        #{preload_fonts()}
      </head>
      <body>
        <div class="site-wrapper">
          #{render_header(base, current_path, nav_items)}

          <main class="main">
            <div class="container">
              #{render_breadcrumb(breadcrumb)}
              <article class="prose">
                #{body_html}
              </article>
              #{render_doc_nav(nav_links, base)}
            </div>
          </main>

          #{render_footer(base, nav_items)}
        </div>

        #{render_scripts(base)}
      </body>
    </html>
    """
  end

  defp preload_fonts do
    # Preconnect to system font origins if needed in the future
    ""
  end

  defp render_header(base, current_path, nav_items) do
    """
    <header class="header">
      <div class="container header__inner">
        <a class="header__brand" href="#{escape(base)}/">
          #{render_logo()}
          #{@app_name}
        </a>
        <nav class="header__nav" id="desktop-nav">
          #{render_nav_links(base, current_path, nav_items)}
          #{render_theme_toggle()}
        </nav>
        <div class="header__mobile-controls">
          #{render_theme_toggle()}
          #{render_hamburger()}
        </div>
      </div>
    </header>
    #{render_mobile_nav(base, current_path, nav_items)}
    """
  end

  defp render_hamburger do
    """
    <button class="nav-toggle" type="button" aria-label="Open navigation menu" aria-expanded="false" aria-controls="mobile-nav">
      <svg class="nav-toggle__icon nav-toggle__icon--menu" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <line x1="3" y1="6" x2="21" y2="6"/>
        <line x1="3" y1="12" x2="21" y2="12"/>
        <line x1="3" y1="18" x2="21" y2="18"/>
      </svg>
      <svg class="nav-toggle__icon nav-toggle__icon--close" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <line x1="18" y1="6" x2="6" y2="18"/>
        <line x1="6" y1="6" x2="18" y2="18"/>
      </svg>
    </button>
    """
  end

  defp render_mobile_nav(base, current_path, nav_items) do
    links =
      nav_items
      |> Enum.map(fn item ->
        href = item["href"]
        label = item["label"]
        is_active = is_nav_active?(href, current_path)
        active_class = if is_active, do: " mobile-nav__link--active", else: ""

        """
        <a class="mobile-nav__link#{active_class}" href="#{escape(base)}#{escape(href)}">#{escape(label)}</a>
        """
      end)
      |> Enum.join("")

    """
    <div class="mobile-nav" id="mobile-nav" aria-hidden="true">
      <nav class="mobile-nav__body">
        #{links}
      </nav>
    </div>
    <div class="mobile-nav__overlay" id="mobile-nav-overlay" aria-hidden="true"></div>
    """
  end

  defp render_logo do
    """
    <svg class="header__logo" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/>
      <polyline points="14 2 14 8 20 8"/>
      <line x1="16" y1="13" x2="8" y2="13"/>
      <line x1="16" y1="17" x2="8" y2="17"/>
      <line x1="10" y1="9" x2="8" y2="9"/>
    </svg>
    """
  end

  defp render_nav_links(base, current_path, nav_items) do
    nav_items
    |> Enum.map(fn item ->
      href = item["href"]
      label = item["label"]
      is_active = is_nav_active?(href, current_path)
      active_class = if is_active, do: " header__link--active", else: ""

      """
      <a class="header__link#{active_class}" href="#{escape(base)}#{escape(href)}">#{escape(label)}</a>
      """
    end)
    |> Enum.join("")
  end

  defp is_nav_active?(_href, nil), do: false
  defp is_nav_active?("/", current_path), do: current_path in ["index.md", "index"]
  defp is_nav_active?(href, current_path) do
    href_normalized = String.trim_leading(href, "/")
    path_normalized = String.trim_trailing(current_path, ".md")

    String.starts_with?(path_normalized, href_normalized)
  end

  defp render_theme_toggle do
    """
    <button class="theme-toggle" type="button" aria-label="Toggle theme" title="Toggle light/dark mode">
      <svg class="icon-sun" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="12" cy="12" r="5"/>
        <line x1="12" y1="1" x2="12" y2="3"/>
        <line x1="12" y1="21" x2="12" y2="23"/>
        <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>
        <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
        <line x1="1" y1="12" x2="3" y2="12"/>
        <line x1="21" y1="12" x2="23" y2="12"/>
        <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>
        <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
      </svg>
      <svg class="icon-moon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
      </svg>
    </button>
    """
  end

  defp render_breadcrumb(nil), do: ""
  defp render_breadcrumb([]), do: ""
  defp render_breadcrumb(items) do
    breadcrumb_items =
      items
      |> Enum.with_index()
      |> Enum.map(fn {item, idx} ->
        is_last = idx == length(items) - 1

        if is_last do
          """
          <span class="breadcrumb__current">#{escape(item.label)}</span>
          """
        else
          """
          <a class="breadcrumb__link" href="#{escape(item.href)}">#{escape(item.label)}</a>
          <span class="breadcrumb__separator" aria-hidden="true">/</span>
          """
        end
      end)
      |> Enum.join("")

    """
    <nav class="breadcrumb" aria-label="Breadcrumb">
      #{breadcrumb_items}
    </nav>
    """
  end

  defp render_doc_nav(nil, _base), do: ""
  defp render_doc_nav(%{prev: nil, next: nil}, _base), do: ""
  defp render_doc_nav(nav_links, base) do
    prev_html = case nav_links.prev do
      nil -> ""
      link ->
        """
        <a class="doc-nav__link doc-nav__link--prev" href="#{escape(base)}#{escape(link.href)}">
          <span class="doc-nav__label">Previous</span>
          <span class="doc-nav__title">#{escape(link.title)}</span>
        </a>
        """
    end

    next_html = case nav_links.next do
      nil -> ""
      link ->
        """
        <a class="doc-nav__link doc-nav__link--next" href="#{escape(base)}#{escape(link.href)}">
          <span class="doc-nav__label">Next</span>
          <span class="doc-nav__title">#{escape(link.title)}</span>
        </a>
        """
    end

    if prev_html == "" and next_html == "" do
      ""
    else
      """
      <nav class="doc-nav" aria-label="Document navigation">
        #{prev_html}
        #{next_html}
      </nav>
      """
    end
  end

  defp render_footer(base, nav_items) do
    # Use nav items for footer links (skip Home since it's the brand link)
    footer_links =
      nav_items
      |> Enum.reject(fn item -> item["href"] == "/" end)
      |> Enum.map(fn item ->
        """
        <a class="footer__link" href="#{escape(base)}#{escape(item["href"])}">#{escape(item["label"])}</a>
        """
      end)
      |> Enum.join("")

    """
    <footer class="footer">
      <div class="container footer__inner">
        <span class="footer__text">Powered by #{@app_name}</span>
        <div class="footer__links">
          #{footer_links}
        </div>
      </div>
    </footer>
    """
  end

  defp render_scripts(base) do
    """
    <script id="mermaid-script" defer src="#{escape(base)}/assets/mermaid.min.js"></script>
    <script>
    (function() {
      // Initialize Mermaid when script loads (handles defer timing correctly)
      const mermaidScript = document.getElementById('mermaid-script');
      if (mermaidScript) {
        mermaidScript.onload = function() {
          if (window.mermaid) {
            mermaid.initialize({ startOnLoad: true, securityLevel: "strict" });
          }
        };
      }
      // Theme toggle (handle both desktop and mobile toggle buttons)
      const toggles = document.querySelectorAll('.theme-toggle');
      const html = document.documentElement;

      function getPreferredTheme() {
        const saved = localStorage.getItem('theme');
        if (saved) return saved;
        return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
      }

      function setTheme(theme) {
        html.setAttribute('data-theme', theme);
        localStorage.setItem('theme', theme);
      }

      // Initialize theme
      setTheme(getPreferredTheme());

      // Toggle handler for all theme toggle buttons
      toggles.forEach(function(toggle) {
        toggle.addEventListener('click', function() {
          const current = html.getAttribute('data-theme') || getPreferredTheme();
          setTheme(current === 'dark' ? 'light' : 'dark');
        });
      });

      // Listen for system preference changes
      window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function(e) {
        if (!localStorage.getItem('theme')) {
          setTheme(e.matches ? 'dark' : 'light');
        }
      });

      // Mobile navigation toggle
      const navToggle = document.querySelector('.nav-toggle');
      const mobileNav = document.getElementById('mobile-nav');
      const overlay = document.getElementById('mobile-nav-overlay');

      function openMobileNav() {
        mobileNav.classList.add('mobile-nav--open');
        overlay.classList.add('mobile-nav__overlay--visible');
        navToggle.setAttribute('aria-expanded', 'true');
        navToggle.setAttribute('aria-label', 'Close navigation menu');
        mobileNav.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';
        // Focus first link
        const firstLink = mobileNav.querySelector('.mobile-nav__link');
        if (firstLink) firstLink.focus();
      }

      function closeMobileNav() {
        mobileNav.classList.remove('mobile-nav--open');
        overlay.classList.remove('mobile-nav__overlay--visible');
        navToggle.setAttribute('aria-expanded', 'false');
        navToggle.setAttribute('aria-label', 'Open navigation menu');
        mobileNav.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
        navToggle.focus();
      }

      if (navToggle && mobileNav && overlay) {
        navToggle.addEventListener('click', function() {
          const isOpen = mobileNav.classList.contains('mobile-nav--open');
          if (isOpen) {
            closeMobileNav();
          } else {
            openMobileNav();
          }
        });

        // Close on overlay click
        overlay.addEventListener('click', closeMobileNav);

        // Close on Escape key
        document.addEventListener('keydown', function(e) {
          if (e.key === 'Escape' && mobileNav.classList.contains('mobile-nav--open')) {
            closeMobileNav();
          }
        });

        // Close mobile nav on link click (navigating away)
        mobileNav.querySelectorAll('.mobile-nav__link').forEach(function(link) {
          link.addEventListener('click', closeMobileNav);
        });
      }

      // Code block copy buttons
      document.querySelectorAll('pre').forEach(function(pre) {
        const code = pre.querySelector('code');
        if (!code) return;

        // Skip mermaid diagrams - they are rendered by Mermaid.js
        if (code.classList.contains('mermaid')) return;

        // Wrap in container
        const wrapper = document.createElement('div');
        wrapper.className = 'code-block';
        pre.parentNode.insertBefore(wrapper, pre);
        wrapper.appendChild(pre);

        // Add copy button
        const button = document.createElement('button');
        button.className = 'code-block__copy';
        button.type = 'button';
        button.title = 'Copy code';
        button.setAttribute('aria-label', 'Copy code to clipboard');
        button.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>';

        button.addEventListener('click', function() {
          const text = code.textContent;
          navigator.clipboard.writeText(text).then(function() {
            button.classList.add('code-block__copy--copied');
            button.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';
            setTimeout(function() {
              button.classList.remove('code-block__copy--copied');
              button.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>';
            }, 2000);
          }).catch(function(err) {
            console.error('Failed to copy:', err);
          });
        });

        wrapper.appendChild(button);

        // Add language label if present
        const langClass = Array.from(code.classList).find(function(c) {
          return c.startsWith('language-');
        });
        if (langClass) {
          const lang = langClass.replace('language-', '');
          const label = document.createElement('span');
          label.className = 'code-block__lang';
          label.textContent = lang;
          wrapper.appendChild(label);
        }
      });
    })();
    </script>
    """
  end

  defp build_breadcrumb(nil), do: nil
  defp build_breadcrumb("index.md"), do: nil
  defp build_breadcrumb("index"), do: nil
  defp build_breadcrumb(path) do
    base = base_path()
    path = String.trim_trailing(path, ".md")
    parts = String.split(path, "/")

    # Build breadcrumb items
    items = [%{label: "Home", href: "#{base}/"}]

    {breadcrumbs, _} =
      parts
      |> Enum.reduce({items, ""}, fn part, {acc, current_path} ->
        new_path = if current_path == "", do: part, else: "#{current_path}/#{part}"
        label = part |> String.replace("-", " ") |> String.replace("_", " ") |> capitalize_words()
        item = %{label: label, href: "#{base}/#{new_path}"}
        {acc ++ [item], new_path}
      end)

    breadcrumbs
  end

  defp capitalize_words(str) do
    str
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  # Build doc navigation (prev/next) from the nav items list
  defp build_doc_nav(nil, _nav_items), do: nil
  defp build_doc_nav(_path, []), do: nil
  defp build_doc_nav(current_path, nav_items) do
    normalized = current_path |> String.trim_trailing(".md") |> String.trim_trailing("/index")

    doc_order =
      Enum.map(nav_items, fn item ->
        path = item["href"] |> String.trim_leading("/")
        path = if path == "", do: "index", else: path
        %{path: path, title: item["label"], href: item["href"]}
      end)

    current_idx = Enum.find_index(doc_order, fn doc ->
      doc.path == normalized or doc.path == "#{normalized}/index"
    end)

    case current_idx do
      nil -> %{prev: nil, next: nil}
      idx ->
        prev = if idx > 0, do: Enum.at(doc_order, idx - 1), else: nil
        next = if idx < length(doc_order) - 1, do: Enum.at(doc_order, idx + 1), else: nil
        %{prev: prev, next: next}
    end
  end

  defp base_path do
    System.get_env("MDPUB_BASE_PATH", "")
    |> String.trim()
    |> String.trim_trailing("/")
  end

  # Minimal HTML escape
  defp escape(nil), do: ""

  defp escape(str) when is_binary(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end
end
