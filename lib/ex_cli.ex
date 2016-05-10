defmodule ExCLI do
  @moduledoc """
  Module containing functions to interact with modules using `ExCLI.DSL`
  """

  @doc """
  Parse the arguments with a module using `ExCLI.DSL`

  ## Example

  ```
  case ExCLI.parse(MyApp.CLI) do
    {:ok, command, context} ->
      do_something(command, context)
    {:error, reason, details} ->
      handle_error(reason, details)
  end
  ```
  """
  @spec parse(atom, [String.t]) :: {:ok, atom, map} | {:error, atom, Keyword.t}
  def parse(module, args \\ System.argv) do
    app = module.__app__
    ExCLI.Parser.parse(app, args)
  end

  @doc """
  Parse and run the arguments with a module using `ExCLI.DSL`

  ## Example

    ```
    ExCLI.run(MyApp.CLI)

    ExCLI.run(MyApp.CLI, ["some", "args"])
    ```
  """
  @spec run(atom, [String.t]) :: any | {:error, atom, Keyword.t}
  def run(module, args \\ System.argv) do
    case parse(module, args) do
      {:ok, command, context} ->
        module.__run__(command, context)
      {:error, _reason, _details} = err ->
        err
    end
  end
end
