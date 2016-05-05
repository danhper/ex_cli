defmodule ExCLI.DSLTest do
  use ExUnit.Case

  defmodule SampleCLI do
    use ExCLI.DSL

    name "mycli"
    description "My CLI"
    long_description ~s"""
    This is my long description
    """

    command :hello do
      description "Greets the user"
      long_description """
      Gives a nice a warm greeting to whoever would listen
      """

      argument :name
      option :from, help: "the sender of the hello"

      run do
        if from = options[:from] do
          IO.puts("#{from} says")
        end
        IO.puts("Hello #{name}")
      end
    end
  end

  test "DSL creates a cli object" do
    assert function_exported?(SampleCLI, :__cli__, 0)
    cli = SampleCLI.__cli__
    assert cli.name == "mycli"
    assert cli.description == "My CLI"
  end

  test "DSL parses commands" do
    cli = SampleCLI.__cli__
    assert [command] = cli.commands
    assert command.name == :hello
  end
end
