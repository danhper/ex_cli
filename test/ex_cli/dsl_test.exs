defmodule ExCLI.DSLTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias MyApp.SampleCLI
  alias ExCLI.Argument

  test "creates an app object" do
    assert function_exported?(SampleCLI, :__app__, 0)
    app = SampleCLI.__app__
    assert app.name == "mycli"
    assert app.description == "My CLI"
    assert app.long_description == "This is my long description\n"
  end

  test "generate options" do
    app = SampleCLI.__app__
    assert [%Argument{name: :verbose, aliases: [:v], count: true}] = app.options
  end

  test "generates commands" do
    app = SampleCLI.__app__
    assert [command] = app.commands
    assert command.name == :hello
    assert [%Argument{name: name, help: help}] = command.options
    assert command.long_description == "Gives a nice a warm greeting to whoever would listen\n"
    assert name == :from
    assert help == "the sender of hello"
  end

  test "generates __run__ clauses" do
    assert_raise ArgumentError, "command i_dont_exist does not exist", fn ->
      SampleCLI.__run__(:i_dont_exist, %{})
    end
    assert capture_io(fn ->
      SampleCLI.__run__(:hello, %{name: "world", from: "Daniel", verbose: 0})
    end) == "Daniel says: Hello world!\n"
  end

  test "generates a default name" do
    defmodule MyUnnamedCLI, do: use ExCLI.DSL
    assert MyUnnamedCLI.__app__.name == "my_unnamed_cli"
  end
end
