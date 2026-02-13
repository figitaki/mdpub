defmodule Mdpub.ContentWatcher do
  @moduledoc """
  Watches the content directory for file changes.

  On markdown file changes, invalidates the ETS cache and broadcasts
  via PubSub so connected LiveViews can re-render.

  On nav.yml changes, triggers a nav config reload.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    content_dir = Mdpub.Content.content_dir() |> Path.expand()

    case FileSystem.start_link(dirs: [content_dir]) do
      {:ok, pid} ->
        FileSystem.subscribe(pid)
        Logger.info("mdpub: watching #{content_dir} for changes")
        {:ok, %{content_dir: content_dir, fs: pid}}

      :ignore ->
        Logger.warning("mdpub: file watcher not available (inotify-tools may be missing)")
        :ignore

      {:error, reason} ->
        Logger.error("mdpub: failed to start file watcher: #{inspect(reason)}")
        :ignore
    end
  end

  @impl true
  def handle_info({:file_event, _watcher_pid, {path, _events}}, state) do
    path = to_string(path)

    cond do
      String.ends_with?(path, ".md") ->
        rel = Path.relative_to(Path.expand(path), state.content_dir)
        Mdpub.Content.invalidate(rel)

        Phoenix.PubSub.broadcast(
          Mdpub.PubSub,
          "content:updates",
          {:content_changed, rel}
        )

      String.ends_with?(path, "nav.yml") ->
        Logger.info("mdpub: nav.yml changed, reloading navigation")
        Mdpub.Nav.reload()

      true ->
        :ok
    end

    {:noreply, state}
  end

  def handle_info({:file_event, _watcher_pid, :stop}, state) do
    {:noreply, state}
  end
end
