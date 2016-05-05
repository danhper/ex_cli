defmodule ExCLI.DSLTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  defmodule SampleCLI do
    use ExCLI.DSL

    name "mycli"
    description "My CLI"
    long_description """
    This is my long description
    """

    option :verbose, help: "Increase the verbosity level", aliases: [:v], count: true

    command :hello do
      description "Greets the user"
      long_description """
      Gives a nice a warm greeting to whoever would listen
      """

      argument :name
      option :from, help: "the sender of hello"

      run context do
        if from = context.options[:from] do
          IO.write("#{from} says: ")
        end
        IO.puts("Hello #{context.name}!")
      end
    end
  end

  test "creates an app object" do
    assert function_exported?(SampleCLI, :__app__, 0)
    app = SampleCLI.__app__
    assert app.name == "mycli"
    assert app.description == "My CLI"
    assert app.long_description == "This is my long description\n"
  end

  test "generate options" do
    app = SampleCLI.__app__
    assert [{:verbose, verbose_args}] = app.options
    assert verbose_args[:aliases] == [:v]
    assert verbose_args[:count]
  end

  test "generates commands" do
    app = SampleCLI.__app__
    assert [command] = app.commands
    assert command.name == :hello
    assert [{option, option_args}] = command.options
    assert command.long_description == "Gives a nice a warm greeting to whoever would listen\n"
    assert option == :from
    assert option_args[:help] == "the sender of hello"
  end

  test "generates __run__ clauses" do
    assert_raise ArgumentError, "command i_dont_exist does not exist", fn ->
      SampleCLI.__run__(:i_dont_exist, %{})
    end
    assert capture_io(fn ->
      SampleCLI.__run__(:hello, %{name: "world", options: [from: "Daniel"]})
    end) == "Daniel says: Hello world!\n"
  end

  test "generates a default name" do
    defmodule MyUnnamedCLI, do: use ExCLI.DSL
    assert MyUnnamedCLI.__app__.name == "my_unnamed_cli"
  end
end
