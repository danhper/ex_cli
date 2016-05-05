defmodule ExCLI do
  defmacro __using__(_opts) do
    quote do
      use ExCLI.DSL
    end
  end

  def process(module, args, options \\ []) do
    cli = module.__cli__
    IO.inspect(cli)
    IO.inspect(args)
    IO.inspect(options)
  end
end
