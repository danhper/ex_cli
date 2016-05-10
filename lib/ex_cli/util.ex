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
end
