defmodule Mdpub.ContentWatcher do
  @moduledoc false

  use GenServer
  require Logger

  def start_link(content_dir) do
    GenServer.start_link(__MODULE__, content_dir, name: __MODULE__)
  end

  @impl true
  def init(content_dir) do
    content_dir = Path.expand(content_dir)

    {:ok, pid} = FileSystem.start_link(dirs: [content_dir])
    FileSystem.subscribe(pid)

    Logger.info("mdpub: watching #{content_dir} for changes")

    {:ok, %{content_dir: content_dir, fs: pid}}
  end

  @impl true
  def handle_info({:file_event, _watcher_pid, {path, _events}}, state) do
    path = to_string(path)

    cond do
      String.ends_with?(path, ".md") ->
        rel = Path.relative_to(Path.expand(path), state.content_dir)
        Mdpub.Content.invalidate(rel)

      Path.basename(path) == "_nav.json" ->
        Mdpub.Content.invalidate({:nav_config, Path.expand(path)})

      true ->
        :ok
    end

    {:noreply, state}
  end

  def handle_info({:file_event, _watcher_pid, :stop}, state) do
    {:noreply, state}
  end
end
