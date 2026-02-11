defmodule MdpubTest do
  use ExUnit.Case

  test "content_dir defaults to ./content" do
    assert Mdpub.Content.content_dir() |> String.ends_with?("content")
  end
end
