defmodule MdpubWeb.Layouts do
  @moduledoc """
  Layout components for mdpub.

  Provides the root HTML shell and the app-level layout
  (header, main content area, footer).
  """

  use MdpubWeb, :html

  embed_templates "layouts/*"

  @doc """
  Renders flash messages.
  """
  attr :flash, :map, required: true

  def flash_group(assigns) do
    ~H"""
    <div :if={msg = Phoenix.Flash.get(@flash, :info)} class="callout callout--info" role="alert">
      <div class="callout__content"><%= msg %></div>
    </div>
    <div :if={msg = Phoenix.Flash.get(@flash, :error)} class="callout callout--danger" role="alert">
      <div class="callout__content"><%= msg %></div>
    </div>
    """
  end

  @doc """
  Checks if a navigation link should be marked active.
  """
  def nav_active?(_href, nil), do: false
  def nav_active?("/", current_path), do: current_path in ["index.md", "index"]

  def nav_active?(href, current_path) do
    href_normalized = String.trim_leading(href, "/")
    path_normalized = String.trim_trailing(current_path, ".md")
    String.starts_with?(path_normalized, href_normalized)
  end
end
