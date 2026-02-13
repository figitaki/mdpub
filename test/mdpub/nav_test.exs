defmodule Mdpub.NavTest do
  use ExUnit.Case

  describe "loading" do
    test "loads nav items from content/nav.yml" do
      nav = Mdpub.Nav.get()

      assert is_list(nav.nav_items)
      assert length(nav.nav_items) > 0

      first = hd(nav.nav_items)
      assert Map.has_key?(first, :href)
      assert Map.has_key?(first, :label)
    end

    test "loads doc_order from content/nav.yml" do
      nav = Mdpub.Nav.get()

      assert is_list(nav.doc_order)
      assert length(nav.doc_order) > 0

      first = hd(nav.doc_order)
      assert Map.has_key?(first, :path)
      assert Map.has_key?(first, :title)
      assert Map.has_key?(first, :href)
    end
  end

  describe "fallback" do
    test "reload/0 falls back to empty nav when nav.yml is missing" do
      tmp_dir = Path.join(System.tmp_dir!(), "mdpub-nav-#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp_dir)

      original = System.get_env("MDPUB_CONTENT_DIR")

      try do
        System.put_env("MDPUB_CONTENT_DIR", tmp_dir)
        Mdpub.Nav.reload()
        Process.sleep(20)

        assert %{nav_items: [], doc_order: []} = Mdpub.Nav.get()
      after
        if original,
          do: System.put_env("MDPUB_CONTENT_DIR", original),
          else: System.delete_env("MDPUB_CONTENT_DIR")

        File.rm_rf!(tmp_dir)
        Mdpub.Nav.reload()
        Process.sleep(20)
      end
    end
  end
end
