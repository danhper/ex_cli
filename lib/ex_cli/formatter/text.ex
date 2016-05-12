defmodule ExCLI.Formatter.Text do
  @moduledoc false

  alias ExCLI.{Argument, Util}

  def format(app, opts \\ []) do
    banner = "usage: #{opts[:prefix]}#{app.name} "
    padding = byte_size(banner)
    width = Keyword.get(opts, :width, 80) - padding
    arguments = format_options(app.options) ++ ["<command>", "[<args>]"]
    formatted_arguments = Util.pretty_join(arguments, width: width, padding: padding)

    banner
    <> formatted_arguments
    <> "\n\nCommands\n   "
    <> format_commands(app.commands)
  end

  def format_options(options, opts \\ []) do
    options
    |> Enum.map(&format_option(&1, opts))
  end

  def format_option(option, _opts \\ []) do
    option_name = Atom.to_string(option.name)
    formatted_option = Enum.join([format_option_name(option_name), format_argument(option)])
    format_optional(formatted_option, !option.required)
  end

  def format_commands(commands) do
    space_size = commands_space_size(commands)
    commands
    |> Enum.map(&format_command(&1, space_size: space_size))
    |> Enum.join("\n   ")
  end

  def format_command(command, opts \\ []) do
    space_size = Keyword.get(opts, :space_size, 2)
    name = Atom.to_string(command.name)
    if description = command.description do
      name <> String.duplicate(" ", space_size) <> description
    else
      name
    end
  end

  defp commands_space_size(commands) do
    command_lengths = commands |> Enum.map(&(&1.name |> to_string |> byte_size))
    Enum.max(command_lengths) - Enum.min(command_lengths) + 3
  end

  defp format_argument(%Argument{type: :boolean}), do: nil
  defp format_argument(%Argument{count: true}), do: nil
  defp format_argument(%Argument{accumulate: true}), do: nil
  defp format_argument(option) do
    metavar = if option.metavar, do: option.metavar, else: to_string(option.name)
    "=<" <> metavar <> ">"
  end

  defp format_option_name(name) when byte_size(name) == 1, do: "-#{name}"
  defp format_option_name(name) do
    name = name |> to_string |> String.replace("_", "-")
    "--#{name}"
  end

  defp format_optional(string, false), do: string
  defp format_optional(string, true) do
    "[" <> string <> "]"
  end
end
