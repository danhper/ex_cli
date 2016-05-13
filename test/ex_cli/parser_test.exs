defmodule ExCLI.ParserTest do
  use ExUnit.Case

  alias ExCLI.Parser

  test "errors" do
    assert Parser.parse(%ExCLI.App{}, []) == {:error, :no_command, []}
    assert Parser.parse(%ExCLI.App{}, ["--foo"]) == {:error, :unknown_option, [name: :foo]}
    assert Parser.parse(%ExCLI.App{}, ["foo"]) == {:error, :unknown_command, [name: :foo]}
    assert Parser.parse(app(:hello, [foo: []]), ["hello"]) == {:error, :missing_argument, [name: :foo]}
    assert Parser.parse(app(:hello), ["hello", "foo"]) == {:error, :too_many_arguments, [value: "foo"]}
    assert Parser.parse(app(:hello, [], [foo: []]), ["hello", "--foo", "bar", "baz"]) == {:error, :too_many_arguments, [value: "baz"]}
    assert Parser.parse(app(:hello, [foo: [type: :integer]]), ["hello", "a"]) == {:error, :bad_argument, [name: :foo, type: :integer]}
    assert Parser.parse(app(:hello, [], [foo: [type: :integer]]), ["hello", "--foo", "a"]) == {:error, :bad_argument, [name: :foo, type: :integer]}
    assert Parser.parse(app(:hello, [foo: [type: :boolean]]), ["hello", "a"]) == {:error, :bad_argument, [name: :foo, type: :boolean]}
    assert Parser.parse(app(:hello, [], [foo: []]), ["hello", "--foo"]) == {:error, :missing_option_argument, [name: :foo]}
    assert Parser.parse(app(:hello, [], [foo: []]), ["hello", "--foo", "--bar"]) == {:error, :missing_option_argument, [name: :foo]}
  end

  test "basic inputs" do
    assert Parser.parse(app(:hello), ["hello"]) == {:ok, :hello, %{}}
    assert Parser.parse(app(:hello, [foo: []]), ["hello", "bar"]) == {:ok, :hello, %{foo: "bar"}}
    assert Parser.parse(app(:hello, [], [foo: []]), ["hello", "--foo", "bar"]) == {:ok, :hello, %{foo: "bar"}}
  end

  test "as option" do
    assert Parser.parse(app(:hello, [], [foo: [as: :bar]]), ["hello", "--foo", "bar"]) == {:ok, :hello, %{bar: "bar"}}
    assert Parser.parse(app(:hello, [foo: [as: :bar]]), ["hello", "foo"]) == {:ok, :hello, %{bar: "foo"}}
  end

  test "argument lists" do
    assert Parser.parse(app(:hello, [foo: [list: true]]), ["hello"]) == {:ok, :hello, %{foo: []}}
    assert Parser.parse(app(:hello, [foo: [list: true]]), ["hello", "foo"]) == {:ok, :hello, %{foo: ["foo"]}}
    assert Parser.parse(app(:hello, [foo: [list: true]]), ["hello", "foo", "bar"]) == {:ok, :hello, %{foo: ["foo", "bar"]}}
  end

  test "option override" do
    assert Parser.parse(app(:hello, [], [foo: []]), ["hello", "--foo", "bar", "--foo", "baz"]) == {:ok, :hello, %{foo: "baz"}}
  end

  test "accumulate option" do
    assert Parser.parse(app(:hello, [], [foo: [accumulate: true]]), ["hello", "--foo", "bar", "--foo", "baz"]) == {:ok, :hello, %{foo: ["bar", "baz"]}}
  end

  test "type conversion" do
    assert Parser.parse(app(:hello, [foo: [type: :integer]]), ["hello", "1"]) == {:ok, :hello, %{foo: 1}}
    assert Parser.parse(app(:hello, [], [foo: [type: :integer]]), ["hello", "--foo", "1"]) == {:ok, :hello, %{foo: 1}}
    assert Parser.parse(app(:hello, [foo: [type: :float]]), ["hello", "1.4"]) == {:ok, :hello, %{foo: 1.4}}
    assert Parser.parse(app(:hello, [foo: [type: :integer, list: true]]), ["hello", "1", "2", "3"]) == {:ok, :hello, %{foo: [1, 2, 3]}}
    assert Parser.parse(app(:hello, [], [foo: [type: :float, accumulate: true]]), ["hello", "--foo", "1.1", "--foo", "2.2"]) == {:ok, :hello, %{foo: [1.1, 2.2]}}
    assert_raise ArgumentError, ~r/invalid type/, fn ->
      Parser.parse(app(:hello, [], [foo: [type: :foo]]), ["hello", "--foo", "bar"])
    end
  end

  test "boolean options" do
    assert Parser.parse(app(:hello, [], [foo: [type: :boolean]]), ["hello", "--foo"]) == {:ok, :hello, %{foo: true}}
    assert Parser.parse(app(:hello, [], [foo: [type: :boolean]]), ["hello", "--foo", "yes"]) == {:ok, :hello, %{foo: true}}
    assert Parser.parse(app(:hello, [], [foo: [type: :boolean]]), ["hello", "--foo", "no"]) == {:ok, :hello, %{foo: false}}
    assert Parser.parse(app(:hello, [], [foo: [type: :boolean]]), ["hello", "--no-foo"]) == {:ok, :hello, %{foo: false}}
  end

  test "default values" do
    assert Parser.parse(app(:hello, [foo: [default: "bar"]]), ["hello"]) == {:ok, :hello, %{foo: "bar"}}
    assert Parser.parse(app(:hello, [foo: [default: ["bar"], list: true]]), ["hello", "abc"]) == {:ok, :hello, %{foo: ["abc"]}}
    assert Parser.parse(app(:hello, [], [foo: [default: "bar"]]), ["hello"]) == {:ok, :hello, %{foo: "bar"}}
    assert Parser.parse(app(:hello, [], [foo: [default: ["bar"], list: true]]), ["hello", "--foo", "abc"]) == {:ok, :hello, %{foo: ["abc"]}}
  end

  test "required options" do
    assert Parser.parse(app(:hello, [], [foo: [required: true]]), ["hello"]) == {:error, :missing_option, name: :foo}
    assert Parser.parse(app(:hello, [], [foo: [required: true]]), ["hello", "--foo", "bar"]) == {:ok, :hello, %{foo: "bar"}}
  end

  test "aliases" do
    assert Parser.parse(app(:hello, [], [foo: [aliases: [:f]]]), ["hello", "-f", "bar"]) == {:ok, :hello, %{foo: "bar"}}
  end

  test "count" do
    assert Parser.parse(app(:hello, [], [f: [count: :true]]), ["hello", "-fff"]) == {:ok, :hello, %{f: 3}}
    assert Parser.parse(app(:hello, [], [foo: [count: :true]]), ["hello", "--foo", "--foo"]) == {:ok, :hello, %{foo: 2}}
  end

  test "process" do
    assert Parser.parse(app(:hello, [], [foo: [process: {:const, "bar"}]]), ["hello", "--foo"]) == {:ok, :hello, %{foo: "bar"}}
    f = fn _arg, context, args -> {:ok, Map.put(context, :foo, "bar"), args} end
    assert Parser.parse(app(:hello, [], [foo: [process: f]]), ["hello", "--foo"]) == {:ok, :hello, %{foo: "bar"}}
    assert_raise ArgumentError, ~r/invalid processor/, fn ->
      f = fn -> "foo" end
      Parser.parse(app(:hello, [], [foo: [process: f]]), ["hello", "--foo"])
    end
  end

  defp app(command, command_arguments \\ [], command_options \\ [], app_options \\ []) do
    command = command(command, command_arguments, command_options)
    app_options = options(app_options, :option)
    %ExCLI.App{commands: [command], options: app_options}
    |> ExCLI.App.finalize
  end

  defp command(command, arguments, options) do
    arguments = options(arguments, :arg)
    options = options(options, :option)
    %ExCLI.Command{name: command, arguments: arguments, options: options}
  end

  defp options(options, type) do
    options
    |> Enum.map(fn {k, v} -> ExCLI.Argument.new(k, type, v) end)
    |> Enum.reverse
  end
end
