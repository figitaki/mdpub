defmodule MdpubWeb.ErrorHTML do
  @moduledoc """
  Error pages rendered when Phoenix catches exceptions.
  """

  use MdpubWeb, :html

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
