defmodule ExCLI.Argument do
  @moduledoc false

  defstruct [
    :name,
    :metavar,
    :as,
    :default,
    :num,
    :help,
    :arg_type,
    :process,
    list: false,
    accumulate: false,
    type: :string,
    count: false,
    required: false,
    aliases: []
  ]

  @type t :: %__MODULE__{}

  def key(arg) do
    arg.as || arg.name
  end

  def new(name, arg_type, options \\ []) do
    Enum.reduce options, %ExCLI.Argument{name: name, arg_type: arg_type}, fn({key, value}, arg) ->
      Map.put(arg, key, value)
    end
  end
end
