defmodule ExCLI.Argument do
  defstruct [
    :name,
    :metavar,
    :as,
    :default,
    :num,
    :help,
    :arg_type,
    :process,
    type: :string,
    count: false,
    required: false,
    aliases: [],
  ]

  def key(arg) do
    arg.as || arg.name
  end

  def put_in_context(arg, context, value) do
    Map.put(context, key(arg), value)
  end

  def new(name, arg_type, options \\ []) do
    Enum.reduce options, %ExCLI.Argument{name: name, arg_type: arg_type}, fn({key, value}, arg) ->
      Map.put(arg, key, value)
    end
  end
end
