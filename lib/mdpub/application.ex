defmodule Mdpub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      if Mix.env() == :test do
        []
      else
        port =
          System.get_env("PORT", "4000")
          |> String.to_integer()

        [
          Mdpub.Content,
          {Bandit, plug: Mdpub.Web, scheme: :http, port: port}
        ]
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mdpub.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
