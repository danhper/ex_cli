defmodule ExCLI.Formatter.TextTest do
  use ExUnit.Case

  @sample_cli_expected_usage "usage: mycli [--verbose] <command> [<args>]\n\nCommands\n   hello   Greets the user\n   help    Shows help about the command"
  @sample_cli_expected_mix_usage "usage: mycli [--verbose] <command> [<args>]\n\n\nCommands\n\n\t\t\thello   Greets the user\n\n\t\t\thelp    Shows help about the command"

  test "format" do
    assert ExCLI.Formatter.Text.format(MyApp.SampleCLI.__app__) == @sample_cli_expected_usage
  end

  test "format for mix" do
    assert ExCLI.Formatter.Text.format(MyApp.SampleCLI.__app__, mix: true) == @sample_cli_expected_mix_usage
  end
end
