defmodule ExCLI.Formatter.TextTest do
  use ExUnit.Case

  @complex_cli_usage """
  usage: mycli [-v] [--debug] [--base-directory=<directory>] [--log-file=<file>]
               <command> [<args>]

  Commands
     talk    Talks to the user
     hello   Greets the user
  """

  @complex_cli_mix_usage """
  usage: mycli [-v] [--debug] [--base-directory=<directory>] [--log-file=<file>]

  \t\t\t\t\t\t\t\t\t\t\t\t\t<command> [<args>]


  Commands

  \t\t\ttalk    Talks to the user

  \t\t\thello   Greets the user
  """

  test "format" do
    assert ExCLI.Formatter.Text.format(MyApp.ComplexCLI.__app__) == expected(@complex_cli_usage)
  end

  test "format for mix" do
    assert ExCLI.Formatter.Text.format(MyApp.ComplexCLI.__app__, mix: true) == expected(@complex_cli_mix_usage)
  end

  defp expected(output) do
    output |> String.trim_trailing("\n")
  end
end
