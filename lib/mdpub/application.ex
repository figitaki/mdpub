defmodule Mdpub.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        {Phoenix.PubSub, name: Mdpub.PubSub},
        Mdpub.Content,
        Mdpub.Nav
      ] ++
        maybe_watcher() ++
        [
          MdpubWeb.Endpoint
        ]

    opts = [strategy: :one_for_one, name: Mdpub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    MdpubWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp maybe_watcher do
    if Mdpub.Content.watcher?() do
      [Mdpub.ContentWatcher]
    else
      []
    end
  end
end
