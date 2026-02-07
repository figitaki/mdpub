defmodule Mdpub.Content do
  @moduledoc """
  Content lookup, Markdown rendering, and a small ETS cache.

  Paths are resolved under a configured content directory.

  Rules:
  - `/` renders `index.md`
  - `/foo` renders `foo.md` if present, else `foo/index.md`
  - Nested paths map naturally: `/foo/bar` => `foo/bar.md` or `foo/bar/index.md`
  """

  @cache_table __MODULE__.Cache

  require Logger

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [[]]}
    }
  end

  def start_link(_opts) do
    :ets.new(@cache_table, [:named_table, :public, read_concurrency: true])

    if watcher?() do
      Mdpub.ContentWatcher.start_link(content_dir())
    else
      Logger.info("mdpub: file watcher disabled")
    end

    {:ok, self()}
  end

  def content_dir do
    System.get_env("MDPUB_CONTENT_DIR", Path.expand("content"))
  end

  def watcher? do
    System.get_env("MDPUB_WATCH", "true") in ["1", "true", "TRUE", "yes", "on"]
  end

  @doc """
  Resolve a requested route path (list of segments) into a page.

  Returns:
  - `{:ok, %{path: rel, file: abs, title: title, body_html: html}}`
  - `{:error, :not_found}`
  """
  def lookup(path_segments, content_dir) when is_list(path_segments) do
    rel = normalize_requested_path(path_segments)

    with {:ok, {abs, rel_for_cache}} <- resolve_markdown_file(rel, content_dir),
         {:ok, page} <- read_and_render(abs, rel_for_cache) do
      {:ok, page}
    else
      {:error, :not_found} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  def invalidate(rel_path) do
    :ets.delete(@cache_table, rel_path)
    :ok
  end

  def invalidate_all do
    :ets.delete_all_objects(@cache_table)
    :ok
  end

  defp normalize_requested_path([]), do: "index"

  defp normalize_requested_path(segments) do
    segments
    |> Enum.reject(&(&1 in ["", "."]))
    |> Enum.join("/")
    |> case do
      "" -> "index"
      other -> other
    end
  end

  defp resolve_markdown_file(rel, content_dir) do
    root = Path.expand(content_dir)

    candidates = [
      Path.join(root, rel <> ".md"),
      Path.join([root, rel, "index.md"])
    ]

    case Enum.find(candidates, &File.regular?/1) do
      nil ->
        {:error, :not_found}

      abs ->
        abs = Path.expand(abs)

        if String.starts_with?(abs, root <> "/") or abs == root do
          rel_for_cache = Path.relative_to(abs, root)
          {:ok, {abs, rel_for_cache}}
        else
          {:error, :path_escape}
        end
    end
  end

  defp read_and_render(abs, rel_for_cache) do
    case File.stat(abs) do
      {:ok, %File.Stat{mtime: mtime}} ->
        case :ets.lookup(@cache_table, rel_for_cache) do
          [{^rel_for_cache, ^mtime, page}] ->
            {:ok, page}

          _ ->
            with {:ok, md} <- File.read(abs),
                 {:ok, body_html} <- markdown_to_html(md) do
              title = infer_title(md, rel_for_cache)

              page = %{
                path: rel_for_cache,
                file: abs,
                title: title,
                body_html: body_html
              }

              :ets.insert(@cache_table, {rel_for_cache, mtime, page})
              {:ok, page}
            end
        end

      {:error, reason} ->
        {:error, {:stat_failed, reason}}
    end
  end

  defp markdown_to_html(md) do
    options =
      Earmark.Options.make_options!(
        smartypants: false,
        code_class_prefix: "language-",
        postprocessor: &postprocessor/1
      )

    # Earmark returns {:ok, html, warnings}
    case Earmark.as_html(md, options) do
      {:ok, html, _warnings} -> {:ok, html}
      {:error, html, _warnings} -> {:ok, html}
    end
  end

  # Combined postprocessor that handles multiple transformations
  defp postprocessor(node) do
    node
    |> mermaid_postprocessor()
    |> task_list_postprocessor()
  end

  defp mermaid_postprocessor({"pre", pre_attrs, [{"code", code_attrs, code_content, code_meta}], meta}) do
    if mermaid_code_block?(code_attrs) do
      # Earmark adds `language-mermaid` class (via code_class_prefix option).
      # Mermaid.js queries for `.mermaid` nodes, so we add that class explicitly.
      #
      # We only add `mermaid` to <code>, not <pre>. If we added it to <pre>,
      # Mermaid would try to parse the *HTML* inside <pre> (including the
      # nested <code> tag), which fails with "Syntax error in text".
      code_attrs = ensure_class(code_attrs, "mermaid")
      {"pre", pre_attrs, [{"code", code_attrs, code_content, code_meta}], meta}
    else
      {"pre", pre_attrs, [{"code", code_attrs, code_content, code_meta}], meta}
    end
  end

  defp mermaid_postprocessor(node), do: node

  # Task list postprocessor: converts GitHub-style task list items to checkboxes
  # Handles: - [ ] unchecked and - [x] or - [X] checked items
  #
  # Note: We use {:replace, node} to replace the entire node including children.
  # Returning just {tag, attrs, children, meta} would cause Earmark to ignore
  # the children and descend into the original content.
  defp task_list_postprocessor({"li", attrs, [first_child | rest], meta} = node) when is_binary(first_child) do
    case parse_task_item(first_child) do
      {:task, checked, remaining_text} ->
        checkbox = build_checkbox(checked)
        new_children = [checkbox, remaining_text | rest]
        attrs = ensure_class(attrs, "task-list-item")
        {:replace, {"li", attrs, new_children, meta}}

      :not_task ->
        node
    end
  end

  # Handle li with nested elements (e.g., paragraph inside li in loose lists)
  defp task_list_postprocessor({"li", attrs, [{"p", p_attrs, [first_child | p_rest], p_meta} | rest], meta})
       when is_binary(first_child) do
    case parse_task_item(first_child) do
      {:task, checked, remaining_text} ->
        checkbox = build_checkbox(checked)
        new_p_children = [checkbox, remaining_text | p_rest]
        new_children = [{"p", p_attrs, new_p_children, p_meta} | rest]
        attrs = ensure_class(attrs, "task-list-item")
        {:replace, {"li", attrs, new_children, meta}}

      :not_task ->
        {"li", attrs, [{"p", p_attrs, [first_child | p_rest], p_meta} | rest], meta}
    end
  end

  defp task_list_postprocessor(node), do: node

  # Parse task item markers: [ ], [x], [X]
  defp parse_task_item(text) when is_binary(text) do
    cond do
      String.starts_with?(text, "[ ] ") ->
        {:task, false, String.slice(text, 4..-1//1)}

      String.starts_with?(text, "[x] ") or String.starts_with?(text, "[X] ") ->
        {:task, true, String.slice(text, 4..-1//1)}

      # Handle case without trailing space (end of line)
      text == "[ ]" ->
        {:task, false, ""}

      text in ["[x]", "[X]"] ->
        {:task, true, ""}

      true ->
        :not_task
    end
  end

  # Build checkbox HTML tuple for the AST
  defp build_checkbox(checked) do
    attrs =
      [{"type", "checkbox"}, {"disabled", "disabled"}] ++
        if(checked, do: [{"checked", "checked"}], else: [])

    {"input", attrs, [], %{}}
  end

  defp mermaid_code_block?(attrs) do
    case List.keyfind(attrs, "class", 0) do
      {"class", class} ->
        class
        |> String.split()
        |> Enum.member?("language-mermaid")

      _ ->
        false
    end
  end

  defp ensure_class(attrs, class) do
    case List.keyfind(attrs, "class", 0) do
      nil ->
        [{"class", class} | attrs]

      {"class", existing} ->
        classes =
          existing
          |> String.split()

        if class in classes do
          attrs
        else
          new_classes =
            classes
            |> Kernel.++([class])
            |> Enum.uniq()

          List.keyreplace(attrs, "class", 0, {"class", Enum.join(new_classes, " ")})
        end
    end
  end

  defp infer_title(md, rel_for_cache) do
    md
    |> String.split("\n")
    |> Enum.find_value(fn line ->
      case String.trim_leading(line) do
        "# " <> rest -> String.trim(rest)
        _ -> nil
      end
    end)
    |> case do
      nil ->
        rel_for_cache
        |> Path.rootname()
        |> String.replace("_", " ")
        |> String.replace("-", " ")

      title ->
        title
    end
  end
end
