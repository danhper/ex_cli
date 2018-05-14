defmodule ExCLI.Formatter.Text do
  @moduledoc false

  alias ExCLI.{Argument, Util}

  def format(app, opts \\ []) do
    opts = opts
    |> Keyword.put_new(:name, app.name)
    |> Keyword.put_new(:default_command, app.default_command)
    |> make_app_opts()
    command = if is_nil(app.default_command), do: "<command>", else: "[<command>]"
    arguments = format_options(app.options) ++ [command, "[<args>]"]
    formatted_arguments = Util.pretty_join(arguments, opts)

    opts[:banner]
    <> formatted_arguments
    <> "\n#{opts[:newline]}Commands#{opts[:newline]}" <> String.duplicate(opts[:pad_with], 3)
    <> format_commands(app.commands, opts)
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
    opts = make_opts(opts)
    column_width = command_name_column_width(commands)
    default_command = opts[:default_command]
    commands
    |> Enum.map(&format_command(&1, column_width: column_width, default_command: default_command))
    |> Enum.join("#{opts[:newline]}" <> String.duplicate(opts[:pad_with], 3))
  end

  def format_command(command, opts \\ []) do
    name = Atom.to_string(command.name)
    name_width = command_name_width(command)
    column_width = Keyword.get(opts, :column_width, name_width)
    spaces = column_width - name_width + 3
    default_tag = if command.name == opts[:default_command], do: " (default)", else: ""
    if description = command.description do
      name <> String.duplicate(" ", spaces) <> description <> default_tag
    else
      name <> default_tag
    end
  end

  defp command_name_column_width([]), do: 0
  defp command_name_column_width(commands) do
    command_lengths = commands |> Enum.map(&command_name_width/1)
    Enum.max(command_lengths)
  end

  defp command_name_width(command) do
    command.name |> to_string |> byte_size
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

  defp make_opts(opts) do
    opts
    |> Keyword.put_new(:newline, if(opts[:mix], do: "\n\n", else: "\n"))
    |> Keyword.put_new(:pad_with, if(opts[:mix], do: "\t", else: " "))
  end

  defp make_app_opts(opts) do
    banner = "usage: #{opts[:name]} "
    padding = byte_size(banner)
    opts
    |> Keyword.put_new(:banner, banner)
    |> Keyword.put_new(:padding, padding)
    |> Keyword.put(:width, Keyword.get(opts, :width, 80) - padding)
    |> make_opts()
  end
end
