defmodule Mdpub.ContentTest do
  use ExUnit.Case, async: true

  describe "lookup/2 routing" do
    test "resolves root path to index.md" do
      with_content_dir(fn content_dir ->
        assert {:ok, page} = Mdpub.Content.lookup([], content_dir)
        assert page.path == "index.md"
        assert page.title == "Home"
      end)
    end

    test "resolves nested path to nested/index.md" do
      with_content_dir(fn content_dir ->
        assert {:ok, page} = Mdpub.Content.lookup(["docs"], content_dir)
        assert page.path == "docs/index.md"
        assert page.title == "Docs Home"
      end)
    end
  end

  defp with_content_dir(fun) do
    tmp_dir = Path.join(System.tmp_dir!(), "mdpub-content-#{System.unique_integer([:positive])}")

    try do
      File.mkdir_p!(Path.join(tmp_dir, "docs"))

      File.write!(Path.join(tmp_dir, "index.md"), "# Home\n\nHello")
      File.write!(Path.join(tmp_dir, "docs/index.md"), "# Docs Home\n\nNested")

      fun.(tmp_dir)
    after
      File.rm_rf!(tmp_dir)
    end
  end
end
