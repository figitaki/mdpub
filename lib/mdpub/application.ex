defmodule Mdpub.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = (System.get_env("PORT") || "4000") |> String.to_integer()

    children = [
      # Mdpub.Content owns the ETS cache and (optionally) starts the file watcher.
      {Mdpub.Content, []},
      {Bandit, plug: Mdpub.Web, scheme: :http, port: port}
    ]

    opts = [strategy: :one_for_one, name: Mdpub.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
