defmodule Mdpub.NavTest do
  use ExUnit.Case

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
