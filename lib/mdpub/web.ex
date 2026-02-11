defmodule Mdpub.Web do
  @moduledoc """
  Minimal docs publisher web server.

  Serves Markdown from a content directory, renders to HTML, and wraps in a
  simple theme.
  """

  use Plug.Router

  require Logger

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(Plug.Static,
    at: "/assets",
    from: {:mdpub, "priv/static/assets"},
    gzip: false,
    only: ~w(style.css mermaid.min.js)
  )

  plug(:match)
  plug(:dispatch)

  get "/healthz" do
    send_resp(conn, 200, "ok")
  end

  get "/*path" do
    content_dir = Mdpub.Content.content_dir()
    nav_items = Mdpub.Content.load_nav_config(content_dir)

    case Mdpub.Content.lookup(path, content_dir) do
      {:ok, page} ->
        # page already contains :path from content lookup
        html = Mdpub.PageLayout.render(Map.put(page, :nav_items, nav_items))

        conn
        |> put_resp_content_type("text/html; charset=utf-8")
        |> send_resp(200, html)

      {:error, :not_found} ->
        html = Mdpub.PageLayout.render_404(path, nav_items)

        conn
        |> put_resp_content_type("text/html; charset=utf-8")
        |> send_resp(404, html)

      {:error, reason} ->
        Logger.warning("mdpub lookup failed for #{inspect(path)}: #{inspect(reason)}")

        html = Mdpub.PageLayout.render_error(path, reason, nav_items)

        conn
        |> put_resp_content_type("text/html; charset=utf-8")
        |> send_resp(500, html)
    end
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
