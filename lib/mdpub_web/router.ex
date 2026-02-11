defmodule MdpubWeb.Router do
  use MdpubWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MdpubWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", MdpubWeb do
    get "/healthz", HealthController, :index
  end

  scope "/", MdpubWeb do
    pipe_through :browser

    live_session :content,
      on_mount: [] do
      live "/", ContentLive, :index
      live "/*path", ContentLive, :show
    end
  end
end
