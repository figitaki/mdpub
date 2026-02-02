defmodule Mdpub.PageLayout do
  @moduledoc """
  HTML page layout and rendering for mdpub.

  Provides a consistent shell layout with:
  - Sticky header with branding and navigation
  - Theme toggle (light/dark mode)
  - Breadcrumb navigation
  - Centered content area with optimal reading width
  - Document navigation (prev/next links)
  - Footer
  """

  @app_name "mdpub"

  # Navigation structure - can be extended
  @nav_items [
    %{href: "/", label: "Home"},
    %{href: "/getting-started", label: "Getting Started"},
    %{href: "/docs/routing", label: "Docs"}
  ]

  def render(%{title: title, body_html: body_html, path: path}) do
    breadcrumb = build_breadcrumb(path)
    nav_links = build_doc_nav(path)
    page(title, body_html, breadcrumb, nav_links, path)
  end

  def render(%{title: title, body_html: body_html}) do
    page(title, body_html, nil, nil, nil)
  end

  def render_404(path_segments) do
    requested = "/" <> Enum.join(path_segments, "/")

    body = """
    <h1>Page not found</h1>
    <p>We couldn't find a document at <code>#{escape(requested)}</code>.</p>
    <p><a href="#{base_path()}/">Return to home</a></p>
    """

    page("Not found", body, nil, nil, nil)
  end

  def render_error(path_segments, reason) do
    requested = "/" <> Enum.join(path_segments, "/")

    body = """
    <h1>Something went wrong</h1>
    <p>There was a problem rendering <code>#{escape(requested)}</code>.</p>
    <pre><code>#{escape(inspect(reason))}</code></pre>
    <p><a href="#{base_path()}/">Return to home</a></p>
    """

    page("Error", body, nil, nil, nil)
  end

  defp page(title, body_html, breadcrumb, nav_links, current_path) do
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
          #{render_header(base, current_path)}

          <main class="main">
            <div class="container">
              #{render_breadcrumb(breadcrumb)}
              <article class="prose">
                #{body_html}
              </article>
              #{render_doc_nav(nav_links, base)}
            </div>
          </main>

          #{render_footer(base)}
        </div>

        #{render_scripts()}
      </body>
    </html>
    """
  end

  defp preload_fonts do
    # Preconnect to system font origins if needed in the future
    ""
  end

  defp render_header(base, current_path) do
    """
    <header class="header">
      <div class="container header__inner">
        <a class="header__brand" href="#{escape(base)}/">
          #{render_logo()}
          #{@app_name}
        </a>
        <nav class="header__nav">
          #{render_nav_links(base, current_path)}
          #{render_theme_toggle()}
        </nav>
      </div>
    </header>
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

  defp render_nav_links(base, current_path) do
    @nav_items
    |> Enum.map(fn %{href: href, label: label} ->
      is_active = is_nav_active?(href, current_path)
      active_class = if is_active, do: " header__link--active", else: ""

      """
      <a class="header__link#{active_class}" href="#{escape(base)}#{escape(href)}">#{escape(label)}</a>
      """
    end)
    |> Enum.join("")
  end

  defp is_nav_active?(href, nil), do: false
  defp is_nav_active?("/", current_path), do: current_path in ["index.md", "index"]
  defp is_nav_active?(href, current_path) do
    # Remove leading slash and add .md for comparison
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

  defp render_footer(base) do
    """
    <footer class="footer">
      <div class="container footer__inner">
        <span class="footer__text">Powered by #{@app_name}</span>
        <div class="footer__links">
          <a class="footer__link" href="#{escape(base)}/getting-started">Getting Started</a>
          <a class="footer__link" href="#{escape(base)}/docs/routing">Documentation</a>
        </div>
      </div>
    </footer>
    """
  end

  defp render_scripts do
    """
    <script>
    (function() {
      // Theme toggle
      const toggle = document.querySelector('.theme-toggle');
      const html = document.documentElement;

      // Check for saved theme preference or system preference
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

      // Toggle handler
      if (toggle) {
        toggle.addEventListener('click', function() {
          const current = html.getAttribute('data-theme') || getPreferredTheme();
          setTheme(current === 'dark' ? 'light' : 'dark');
        });
      }

      // Listen for system preference changes
      window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function(e) {
        if (!localStorage.getItem('theme')) {
          setTheme(e.matches ? 'dark' : 'light');
        }
      });

      // Code block copy buttons
      document.querySelectorAll('pre').forEach(function(pre) {
        const code = pre.querySelector('code');
        if (!code) return;

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

  # Document navigation - ordered list of pages
  @doc_order [
    %{path: "index", title: "Home", href: "/"},
    %{path: "getting-started", title: "Getting Started", href: "/getting-started"},
    %{path: "docs/routing", title: "Routing", href: "/docs/routing"}
  ]

  defp build_doc_nav(nil), do: nil
  defp build_doc_nav(current_path) do
    normalized = current_path |> String.trim_trailing(".md") |> String.trim_trailing("/index")

    current_idx = Enum.find_index(@doc_order, fn doc ->
      doc.path == normalized or doc.path == "#{normalized}/index"
    end)

    case current_idx do
      nil -> %{prev: nil, next: nil}
      idx ->
        prev = if idx > 0, do: Enum.at(@doc_order, idx - 1), else: nil
        next = if idx < length(@doc_order) - 1, do: Enum.at(@doc_order, idx + 1), else: nil
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
