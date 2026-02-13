defmodule MdpubWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :mdpub

  @session_options [
    store: :cookie,
    key: "_mdpub_key",
    signing_salt: "mdpub_sign",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve static assets from priv/static
  plug Plug.Static,
    at: "/",
    from: :mdpub,
    gzip: false,
    only: MdpubWeb.static_paths()

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug MdpubWeb.Router
end
