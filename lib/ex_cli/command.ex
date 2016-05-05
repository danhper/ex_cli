defmodule ExCLI.Command do
  defstruct [:name, :description, :long_description, arguments: [], options: []]
end
