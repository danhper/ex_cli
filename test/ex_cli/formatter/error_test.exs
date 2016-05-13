defmodule ExCLI.Formatter.ErrorTest do
  use ExUnit.Case

  alias ExCLI.Formatter.Error

  test "format error messages" do
    assert Error.format(:no_command, []) == "No command provided"
    assert Error.format(:unknown_command, name: :foo) == "Unknown command 'foo'"
    assert Error.format(:missing_argument, name: :foo) == "Missing argument 'foo'"
    assert Error.format(:missing_option, name: :foo) == "Missing required option 'foo'"
    assert Error.format(:missing_option_argument, name: :foo) == "No argument provided for 'foo'"
    assert Error.format(:unknown_option, name: :foo) == "Unknown option 'foo'"
    assert Error.format(:too_many_arguments, value: "foo") == "Unexpected argument 'foo'"
    assert Error.format(:bad_argument, name: :foo, type: :float) == "Could not convert 'foo' to 'float'"
  end
end
