defmodule ExCLI.Command do
  @moduledoc false

  defstruct [
    :name,
    :description,
    :long_description,
    aliases: [],
    arguments: [],
    options: [],
    normalized_options: %{}
  ]

  @type t :: %__MODULE__{
    name: atom,
    description: String.t,
    long_description: String.t,
    aliases: [atom],
    arguments: [ExCLI.Argument.t],
    options: [ExCLI.Argument.t],
    normalized_options: map
  }

  def add_argument(%__MODULE__{arguments: [%ExCLI.Argument{list: true} | _rest]}, _name, _options) do
    raise ArgumentError, "cannot add an argument after a list argument"
  end
  def add_argument(%__MODULE__{arguments: args} = command, name, options) do
    Map.put(command, :arguments, [ExCLI.Argument.new(name, :arg, options) | args])
  end

  def finalize(command, opts) do
    command
    |> Map.put(:arguments, Enum.reverse(command.arguments))
    |> Map.put(:options, Enum.reverse(command.options))
    |> Map.put(:normalized_options, ExCLI.Util.generate_options(command.options, opts))
  end

  def match?(command, name) do
    command.name == name || Enum.any?(command.aliases, &(&1 == name))
  end
end
