defmodule ExCLI do
  defmacro __using__(_opts) do
    quote do
      use ExCLI.DSL
    end
  end

  def process(module, args, options \\ []) do
    app = module.__app__
    IO.inspect(app)
    IO.inspect(args)
    IO.inspect(options)
  end
end
