import Config

config :mdpub, MdpubWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base:
    "test-secret-key-base-that-is-at-least-64-bytes-long-for-phoenix-to-work-properly",
  server: false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime
