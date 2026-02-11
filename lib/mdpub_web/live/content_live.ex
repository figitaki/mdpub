defmodule MdpubWeb.ContentLive do
  @moduledoc """
  LiveView for rendering markdown content pages.

  Subscribes to content change events so pages update automatically
  when markdown files or nav.yml are modified on disk.
  """

  use MdpubWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Mdpub.PubSub, "content:updates")
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    path_segments = params["path"] || []
    content_dir = Mdpub.Content.content_dir()
    nav = Mdpub.Nav.get()

    socket = assign(socket, :path_segments, path_segments)
    socket = assign(socket, :nav_items, nav.nav_items)

    case Mdpub.Content.lookup(path_segments, content_dir) do
      {:ok, page} ->
        breadcrumb = build_breadcrumb(page.path)
        doc_nav = build_doc_nav(page.path, nav.doc_order)

        {:noreply,
         socket
         |> assign(:page, page)
         |> assign(:page_title, page.title)
         |> assign(:current_path, page.path)
         |> assign(:breadcrumb, breadcrumb)
         |> assign(:doc_nav, doc_nav)
         |> assign(:error, nil)}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> assign(:page, nil)
         |> assign(:page_title, "Not Found")
         |> assign(:current_path, nil)
         |> assign(:breadcrumb, nil)
         |> assign(:doc_nav, nil)
         |> assign(:error, :not_found)}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:page, nil)
         |> assign(:page_title, "Error")
         |> assign(:current_path, nil)
         |> assign(:breadcrumb, nil)
         |> assign(:doc_nav, nil)
         |> assign(:error, {:render_error, reason})}
    end
  end

  @impl true
  def handle_info({:content_changed, _rel}, socket) do
    path_segments = socket.assigns.path_segments
    content_dir = Mdpub.Content.content_dir()

    case Mdpub.Content.lookup(path_segments, content_dir) do
      {:ok, page} ->
        {:noreply,
         socket
         |> assign(:page, page)
         |> assign(:page_title, page.title)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info(:nav_updated, socket) do
    nav = Mdpub.Nav.get()
    current_path = socket.assigns[:current_path]

    doc_nav =
      if current_path do
        build_doc_nav(current_path, nav.doc_order)
      end

    {:noreply,
     socket
     |> assign(:nav_items, nav.nav_items)
     |> assign(:doc_nav, doc_nav)}
  end

  # -- Breadcrumb building --

  defp build_breadcrumb(nil), do: nil
  defp build_breadcrumb("index.md"), do: nil
  defp build_breadcrumb("index"), do: nil

  defp build_breadcrumb(path) do
    path = String.trim_trailing(path, ".md")
    parts = String.split(path, "/")

    items = [%{label: "Home", href: "/"}]

    {breadcrumbs, _} =
      Enum.reduce(parts, {items, ""}, fn part, {acc, current_path} ->
        new_path = if current_path == "", do: part, else: "#{current_path}/#{part}"
        label = part |> String.replace("-", " ") |> String.replace("_", " ") |> capitalize_words()
        item = %{label: label, href: "/#{new_path}"}
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

  # -- Document navigation (prev/next) --

  defp build_doc_nav(nil, _doc_order), do: nil

  defp build_doc_nav(current_path, doc_order) do
    normalized =
      current_path
      |> String.trim_trailing(".md")
      |> String.trim_trailing("/index")

    current_idx =
      Enum.find_index(doc_order, fn doc ->
        doc.path == normalized or doc.path == "#{normalized}/index"
      end)

    case current_idx do
      nil ->
        %{prev: nil, next: nil}

      idx ->
        prev = if idx > 0, do: Enum.at(doc_order, idx - 1), else: nil
        next = if idx < length(doc_order) - 1, do: Enum.at(doc_order, idx + 1), else: nil
        %{prev: prev, next: next}
    end
  end
end
