defmodule ExCLI.Util do
  @moduledoc false

  def generate_options(raw_options, opts) do
    Enum.reduce raw_options, %{}, fn option, acc ->
      acc
      |> add_boolean_negation_option(option, opts)
      |> generate_aliases(option)
      |> put_option!(option.name, option)
    end
  end

  defp generate_aliases(app_options, option) do
    Enum.reduce option.aliases, app_options, fn(name, options) ->
      put_option!(options, name, option)
    end
  end

  defp put_option!(app_options, name, option) do
    if Map.has_key?(app_options, name) do
      raise ArgumentError, "duplicated key #{name}"
    else
      Map.put(app_options, name, option)
    end
  end

  defp add_boolean_negation_option(options, option, opts) do
    if option.type == :boolean and !opts[:no_boolean_negation] do
      key = String.to_atom("no_#{option.name}")
      Map.put(options, key, Map.put(option, :process, {:const, false}))
    else
      options
    end
  end

  def pretty_join(strings, opts \\ []) do
    case Keyword.get(opts, :width, 80) do
      :infinity -> Enum.join(strings, " ")
      width ->
        opts =
          opts
          |> Keyword.put_new(:newline, "\n")
          |> Keyword.put_new(:pad_with, " ")
        do_pretty_join(strings, width, [""], opts)
    end
  end
  defp do_pretty_join([], _width, acc, opts) do
    padding = String.duplicate(opts[:pad_with], Keyword.get(opts, :padding, 0))
    acc |> Enum.reverse |> Enum.join("#{opts[:newline]}#{padding}")
  end
  defp do_pretty_join([head | rest], width, [current | others], opts)
      when byte_size(head) + byte_size(current) < width do
    current = current <> separator(current) <> head
    do_pretty_join(rest, width, [current | others], opts)
  end
  defp do_pretty_join([head | rest], width, [current | others], opts) do
    do_pretty_join(rest, width, [head, current | others], opts)
  end
  defp separator(""), do: ""
  defp separator(_), do: " "
end
