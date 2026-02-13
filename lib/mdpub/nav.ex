defmodule Mdpub.Nav do
  @moduledoc """
  Loads and caches navigation configuration from content/nav.yml.

  Provides header navigation items and document ordering for
  prev/next navigation. Reloads automatically when nav.yml changes.
  """

  use GenServer

  # -- Public API --

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Returns the full nav config: %{nav_items: [...], doc_order: [...]}"
  def get do
    GenServer.call(__MODULE__, :get)
  end

  @doc "Returns header navigation items."
  def nav_items do
    get().nav_items
  end

  @doc "Returns the ordered list of documents for prev/next links."
  def doc_order do
    get().doc_order
  end

  @doc "Reload nav.yml from disk and broadcast the change."
  def reload do
    GenServer.cast(__MODULE__, :reload)
  end

  # -- GenServer callbacks --

  @impl true
  def init(_opts) do
    {:ok, load_nav()}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:reload, _state) do
    nav = load_nav()
    Phoenix.PubSub.broadcast(Mdpub.PubSub, "content:updates", :nav_updated)
    {:noreply, nav}
  end

  # -- Private --

  defp load_nav do
    path = nav_yml_path()

    case YamlElixir.read_from_file(path) do
      {:ok, data} ->
        parse_nav(data)

      {:error, _reason} ->
        %{nav_items: [], doc_order: []}
    end
  end

  defp parse_nav(data) do
    nav_items =
      (data["nav"] || [])
      |> Enum.map(fn item ->
        %{href: item["href"], label: item["label"]}
      end)

    doc_order =
      (data["doc_order"] || [])
      |> Enum.map(fn item ->
        %{path: item["path"], title: item["title"], href: item["href"]}
      end)

    %{nav_items: nav_items, doc_order: doc_order}
  end

  defp nav_yml_path do
    Path.join(Mdpub.Content.content_dir(), "nav.yml")
  end
end
