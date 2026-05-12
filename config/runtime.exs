import Config

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  port = String.to_integer(System.get_env("PORT") || "4000")
  host = System.get_env("PHX_HOST") || "localhost"

  # Optional base path for deployments behind a reverse proxy with a path prefix.
  # Documented as MDPUB_BASE_PATH in content/docs/routing.md. Trailing "/" is
  # stripped so "/foo" and "/foo/" both work; empty stays empty.
  base_path =
    System.get_env("MDPUB_BASE_PATH", "")
    |> String.trim_trailing("/")

  url_opts = [host: host, port: 443, scheme: "https"]

  url_opts =
    if base_path == "", do: url_opts, else: Keyword.put(url_opts, :path, base_path)

  config :mdpub, MdpubWeb.Endpoint,
    url: url_opts,
    static_url: url_opts,
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    server: true
end
