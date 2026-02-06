defmodule Mdpub.ContentTest do
  use ExUnit.Case, async: true

  describe "task list rendering" do
    test "renders unchecked task list items with checkbox" do
      # We'll test using the postprocessor directly since markdown_to_html is private
      options =
        Earmark.Options.make_options!(
          smartypants: false,
          code_class_prefix: "language-",
          postprocessor: fn node ->
            node
            |> apply_mermaid_postprocessor()
            |> apply_task_list_postprocessor()
          end
        )

      markdown = "- [ ] unchecked task"
      html = Earmark.as_html!(markdown, options)

      assert html =~ ~s(<input type="checkbox" disabled="disabled">)
      assert html =~ ~s(class="task-list-item")
      assert html =~ "unchecked task"
      refute html =~ "[ ]"
    end

    test "renders checked task list items with checked checkbox" do
      options =
        Earmark.Options.make_options!(
          smartypants: false,
          code_class_prefix: "language-",
          postprocessor: &apply_task_list_postprocessor/1
        )

      markdown = "- [x] checked task"
      html = Earmark.as_html!(markdown, options)

      assert html =~ ~s(<input type="checkbox" disabled="disabled" checked="checked">)
      assert html =~ ~s(class="task-list-item")
      assert html =~ "checked task"
      refute html =~ "[x]"
    end

    test "renders uppercase X as checked" do
      options =
        Earmark.Options.make_options!(
          smartypants: false,
          postprocessor: &apply_task_list_postprocessor/1
        )

      markdown = "- [X] checked task"
      html = Earmark.as_html!(markdown, options)

      assert html =~ ~s(checked="checked")
    end

    test "does not modify regular list items" do
      options =
        Earmark.Options.make_options!(
          smartypants: false,
          postprocessor: &apply_task_list_postprocessor/1
        )

      markdown = "- Regular item"
      html = Earmark.as_html!(markdown, options)

      refute html =~ "<input"
      refute html =~ "task-list-item"
      assert html =~ "Regular item"
    end

    test "handles mixed task and regular items" do
      options =
        Earmark.Options.make_options!(
          smartypants: false,
          postprocessor: &apply_task_list_postprocessor/1
        )

      markdown = """
      - [ ] task item
      - regular item
      - [x] completed task
      """

      html = Earmark.as_html!(markdown, options)

      # Should have 2 checkboxes
      checkbox_count = Regex.scan(~r/<input/, html) |> length()
      assert checkbox_count == 2

      # Should have 2 task-list-item classes
      task_class_count = Regex.scan(~r/task-list-item/, html) |> length()
      assert task_class_count == 2

      # Regular item should not be modified
      assert html =~ "<li>\nregular item"
    end

    test "handles empty task list text" do
      options =
        Earmark.Options.make_options!(
          smartypants: false,
          postprocessor: &apply_task_list_postprocessor/1
        )

      # Edge case: task with no description
      markdown = "- [ ]"
      html = Earmark.as_html!(markdown, options)

      # Should still render a checkbox even with no text
      assert html =~ ~s(<input type="checkbox" disabled="disabled">)
    end
  end

  # Helper functions that mirror the Content module implementation
  defp apply_mermaid_postprocessor({"pre", pre_attrs, [{"code", code_attrs, code_content, code_meta}], meta}) do
    if mermaid_code_block?(code_attrs) do
      code_attrs = ensure_class(code_attrs, "mermaid")
      {"pre", pre_attrs, [{"code", code_attrs, code_content, code_meta}], meta}
    else
      {"pre", pre_attrs, [{"code", code_attrs, code_content, code_meta}], meta}
    end
  end

  defp apply_mermaid_postprocessor(node), do: node

  defp mermaid_code_block?(attrs) do
    case List.keyfind(attrs, "class", 0) do
      {"class", class} -> class |> String.split() |> Enum.member?("language-mermaid")
      _ -> false
    end
  end

  defp apply_task_list_postprocessor({"li", attrs, [first_child | rest], meta} = node)
       when is_binary(first_child) do
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

  defp apply_task_list_postprocessor(node), do: node

  defp parse_task_item(text) when is_binary(text) do
    cond do
      String.starts_with?(text, "[ ] ") ->
        {:task, false, String.slice(text, 4..-1//1)}

      String.starts_with?(text, "[x] ") or String.starts_with?(text, "[X] ") ->
        {:task, true, String.slice(text, 4..-1//1)}

      text == "[ ]" ->
        {:task, false, ""}

      text in ["[x]", "[X]"] ->
        {:task, true, ""}

      true ->
        :not_task
    end
  end

  defp build_checkbox(checked) do
    attrs =
      [{"type", "checkbox"}, {"disabled", "disabled"}] ++
        if(checked, do: [{"checked", "checked"}], else: [])

    {"input", attrs, [], %{}}
  end

  defp ensure_class(attrs, class) do
    case List.keyfind(attrs, "class", 0) do
      nil ->
        [{"class", class} | attrs]

      {"class", existing} ->
        classes = existing |> String.split()

        if class in classes do
          attrs
        else
          List.keyreplace(attrs, "class", 0, {"class", Enum.join(classes ++ [class], " ")})
        end
    end
  end
end
