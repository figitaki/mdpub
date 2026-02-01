defmodule Mdpub.PageLayout do
  @moduledoc false

  @app_name "mdpub"

  def render(%{title: title, body_html: body_html}) do
    page(title, body_html)
  end

  def render_404(path_segments) do
    requested = "/" <> Enum.join(path_segments, "/")

    body = """
    <h1>Not found</h1>
    <p>Could not find a document for <code>#{escape(requested)}</code>.</p>
    <p><a href=\"/\">Go home</a></p>
    """

    page("Not found", body)
  end

  def render_error(path_segments, reason) do
    requested = "/" <> Enum.join(path_segments, "/")

    body = """
    <h1>Error</h1>
    <p>There was a problem rendering <code>#{escape(requested)}</code>.</p>
    <pre>#{escape(inspect(reason))}</pre>
    """

    page("Error", body)
  end

  defp page(title, body_html) do
    base = base_path()

    """
    <!doctype html>
    <html lang=\"en\">
      <head>
        <meta charset=\"utf-8\" />
        <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\" />
        <title>#{escape(title)} · #{@app_name}</title>
        <base href=\"#{escape(base)}/\" />
        <link rel=\"stylesheet\" href=\"#{escape(base)}/assets/style.css\" />
      </head>
      <body>
        <header class=\"top\">
          <div class=\"container\">
            <a class=\"brand\" href=\"#{escape(base)}/\">#{@app_name}</a>
          </div>
        </header>

        <main class=\"container prose\">
          #{body_html}
        </main>

        <footer class=\"footer\">
          <div class=\"container\">
            <span>Served by #{@app_name}</span>
          </div>
        </footer>
      </body>
    </html>
    """
  end

  defp base_path do
    System.get_env("MDPUB_BASE_PATH", "")
    |> String.trim()
    |> String.trim_trailing("/")
  end

  # minimal HTML escape
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
