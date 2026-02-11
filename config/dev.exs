import Config

config :mdpub, MdpubWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base:
    "dev-only-secret-key-base-that-is-at-least-64-bytes-long-for-phoenix-to-work-properly",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:mdpub, ~w(--sourcemap=inline --watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/assets/.*(js|css)$",
      ~r"lib/mdpub_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
