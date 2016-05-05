defmodule ExCLI.App do
  defstruct [:name, :description, :long_description, options: [], commands: []]

  def default_name(mod) do
    mod
    |> Atom.to_string
    |> String.split(".")
    |> List.last
    |> Macro.underscore
  end
end
