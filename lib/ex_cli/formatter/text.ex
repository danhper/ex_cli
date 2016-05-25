defmodule ExCLI.Formatter.Text do
  @moduledoc false

  alias ExCLI.{Argument, Util}

  def format(app, opts \\ []) do
    opts = opts |> Keyword.put_new(:name, app.name) |> make_full_opts()
    arguments = format_options(app.options) ++ ["<command>", "[<args>]"]
    formatted_arguments = Util.pretty_join(arguments, opts)
    options = format_options_details(app.options, Keyword.put(opts, :no_brackets, true))

    [opts[:banner],
     formatted_arguments,
     "\n#{opts[:newline]}Commands#{opts[:newline]}" <> String.duplicate(opts[:pad_char], 3),
     commands_summary(app.commands, opts)] |> IO.iodata_to_binary
  end

  def format_command(command, opts \\ []) do
    name = if(opts[:prefix], do: opts[:prefix] <> " ", else: "") <> to_string(command.name)
    opts = opts |> Keyword.put_new(:name, name) |> make_full_opts()
    arguments = format_options(command.options) ++ Enum.map(command.arguments, & "<#{&1.name}>")
    formatted_arguments = Util.pretty_join(arguments, opts)
    options = format_options_details(command.options, opts)

    [opts[:banner],
     formatted_arguments,
     String.duplicate(opts[:newline], 2),
     "Options",
     opts[:newline],
     options] |> IO.iodata_to_binary
  end

  def format_options(options, opts \\ []) do
    Enum.map(options, &format_option(&1, opts))
  end

  def format_options_details(options, opts) do
    Enum.map(options, &format_option_details(&1, opts))
    |> Enum.join(opts[:newline])
  end

  defp format_option_details(option, opts) do
    [String.duplicate(opts[:pad_char], 3),
     format_option(option, Keyword.put(opts, :no_brackets, true)),
     opts[:newline],
     String.duplicate(opts[:pad_char], 6),
     option.help] |> IO.iodata_to_binary
  end

  def format_option(option, opts \\ []) do
    option_name = Atom.to_string(option.name)
    formatted_option = Enum.join([format_option_name(option_name), format_argument(option)])
    format_optional(formatted_option, !option.required && !opts[:no_brackets])
  end

  def commands_summary(commands, opts \\ []) do
    opts = make_opts(opts)
    space_size = commands_space_size(commands)
    commands
    |> Enum.map(&command_summary(&1, space_size: space_size))
    |> Enum.join("#{opts[:newline]}" <> String.duplicate(opts[:pad_char], 3))
  end

  def command_summary(command, opts \\ []) do
    name = Atom.to_string(command.name)
    if description = command.description do
      spaces = Keyword.get(opts, :space_size, 2) - String.length(name)
      name <> String.duplicate(" ", spaces) <> description
    else
      name
    end
  end

  defp commands_space_size([]), do: 0
  defp commands_space_size(commands) do
    command_lengths = commands |> Enum.map(&(&1.name |> to_string |> byte_size))
    Enum.max(command_lengths) + 3
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
    |> Keyword.put_new(:pad_char, if(opts[:mix], do: "\t", else: " "))
  end

  defp make_full_opts(opts) do
    banner = "usage: #{opts[:name]} "
    padding = byte_size(banner)
    opts
    |> Keyword.put_new(:banner, banner)
    |> Keyword.put_new(:padding, padding)
    |> Keyword.put(:width, Keyword.get(opts, :width, 80) - padding)
    |> make_opts()
  end
end
