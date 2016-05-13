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
    ExCLI.Parser.parse(app(module), args)
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

  @spec run!(atom, [String.t], Keyword.t) :: any
  def run!(module, args \\ System.argv, opts \\ []) do
    case parse(module, args) do
      {:ok, command, context} ->
        module.__run__(command, context)
      {:error, reason, details} ->
        IO.puts(ExCLI.Formatter.Error.format(reason, details))
        IO.puts(usage(module, opts))
        unless opts[:no_halt], do: System.halt(1)
    end
  end

  @doc """
  Displays the usage for the given module
  """
  def usage(module, opts \\ []) do
    ExCLI.Formatter.Text.format(app(module), opts)
  end

  defp app(module), do: module.__app__
end
