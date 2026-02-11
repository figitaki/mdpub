import Config

config :mdpub, MdpubWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MdpubWeb.ErrorHTML],
    layout: false
  ],
  pubsub_server: Mdpub.PubSub,
  live_view: [signing_salt: "mdpub_lv_salt"]

config :esbuild,
  version: "0.21.5",
  mdpub: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
