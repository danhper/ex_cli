defmodule ExCLI.App do
  @moduledoc false

  defstruct [
    :name,
    :description,
    :long_description,
    options: [],
    normalized_options: %{},
    commands: [],
    default_command: nil,
    opts: []
  ]

  @type t ::  %__MODULE__{
    name: String.t | atom,
    description: String.t,
    long_description: String.t,
    options: [ExCLI.Argument.t],
    normalized_options: map,
    commands: [ExCLI.Command.t],
    default_command: atom,
    opts: Keyword.t
  }

  @doc false
  def default_name(mod) do
    mod
    |> Atom.to_string
    |> String.split(".")
    |> List.last
    |> Macro.underscore
  end

  @doc false
  def finalize(app) do
    app = app
    |> Map.put(:options, Enum.reverse(app.options))
    |> Map.put(:commands, Enum.map(app.commands, &ExCLI.Command.finalize(&1, app.opts)))
    |> Map.put(:normalized_options, ExCLI.Util.generate_options(app.options, app.opts))

    if not is_nil(app.default_command) do
      if not Enum.any?(app.commands, &(&1.name == app.default_command)) do
        raise "Default command #{app.default_command} not defined"
      end
    end
    app
  end
end
