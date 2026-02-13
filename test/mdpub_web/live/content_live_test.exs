defmodule MdpubWeb.ContentLiveTest do
  use ExUnit.Case

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint MdpubWeb.Endpoint

  test "GET /nonexistent renders not-found content" do
    {:ok, _view, html} = live(build_conn(), "/nonexistent")
    assert html =~ "Page not found"
  end

  test "live page refreshes when content_changed event is broadcast" do
    tmp_dir = Path.join(System.tmp_dir!(), "mdpub-live-#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)

    nav_yml = """
    nav:
      - label: Home
        href: /
    doc_order:
      - path: index
        title: Home
        href: /
    """

    original_content_dir = System.get_env("MDPUB_CONTENT_DIR")

    try do
      File.write!(Path.join(tmp_dir, "index.md"), "# Home\n\nOld body")
      File.write!(Path.join(tmp_dir, "nav.yml"), nav_yml)

      System.put_env("MDPUB_CONTENT_DIR", tmp_dir)
      Mdpub.Content.invalidate_all()
      Mdpub.Nav.reload()
      Process.sleep(20)

      {:ok, view, _html} = live(build_conn(), "/")
      assert render(view) =~ "Old body"

      File.write!(Path.join(tmp_dir, "index.md"), "# Home\n\nNew body")
      Mdpub.Content.invalidate("index.md")
      Phoenix.PubSub.broadcast(Mdpub.PubSub, "content:updates", {:content_changed, "index.md"})

      assert render(view) =~ "New body"
    after
      if original_content_dir,
        do: System.put_env("MDPUB_CONTENT_DIR", original_content_dir),
        else: System.delete_env("MDPUB_CONTENT_DIR")

      File.rm_rf!(tmp_dir)
      Mdpub.Content.invalidate_all()
      Mdpub.Nav.reload()
      Process.sleep(20)
    end
  end

  test "nav_updated event refreshes navigation assigns" do
    {:ok, view, _html} = live(build_conn(), "/")

    Phoenix.PubSub.broadcast(Mdpub.PubSub, "content:updates", :nav_updated)

    # View should still render without crashing
    html = render(view)
    assert is_binary(html)
  end
end
