defmodule ExCLI.Formatter.Text do
  @moduledoc false

  alias ExCLI.{Argument, Util}

  def format(app, opts \\ []) do
    newline = if opts[:mix], do: "\n\n", else: "\n"
    pad_with = if opts[:mix], do: "\t", else: " "
    name = Keyword.get(opts, :name, app.name)
    banner = "usage: #{name} "
    padding = byte_size(banner)
    width = Keyword.get(opts, :width, 80) - padding
    arguments = format_options(app.options) ++ ["<command>", "[<args>]"]
    join_opts = [width: width, padding: padding, newline: newline, pad_with: pad_with]
    formatted_arguments = Util.pretty_join(arguments, join_opts)

    banner
    <> formatted_arguments
    <> "\n#{newline}Commands#{newline}" <> String.duplicate(pad_with, 3)
    <> format_commands(app.commands, newline: newline, pad_with: pad_with)
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

  def format_commands(commands, opts \\ []) do
    newline = Keyword.get(opts, :newline, "\n")
    pad_with = Keyword.get(opts, :pad_with, " ")
    space_size = commands_space_size(commands)
    commands
    |> Enum.map(&format_command(&1, space_size: space_size))
    |> Enum.join("#{newline}" <> String.duplicate(pad_with, 3))
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
