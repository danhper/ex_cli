defmodule ExCLITest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  test "parse" do
    assert {:ok, :hello, %{name: "world"}} = ExCLI.parse(MyApp.SampleCLI, ["hello", "world"])
    assert {:ok, :hello, %{name: "world"}} = ExCLI.parse(MyApp.SampleCLI, ["hi", "world"])
    assert {:ok, :hello, %{name: "world", verbose: 2}} = ExCLI.parse(MyApp.SampleCLI, ["-vv", "hello", "world"])
  end

  test "run" do
    assert capture_io(fn ->
      ExCLI.run(MyApp.SampleCLI, ["hello", "world"])
    end) == "Hello world!\n"

    assert capture_io(fn ->
      ExCLI.run(MyApp.SampleCLI, ["hi", "world"])
    end) == "Hello world!\n"

    assert capture_io(fn ->
      ExCLI.run(MyApp.SampleCLIWithDefaultCommand, [])
    end) == "Hello world with defaults!\n"

    assert capture_io(fn ->
      ExCLI.run(MyApp.SampleCLI, ["-vv", "hello", "world", "--from", "Daniel"])
    end) == "Running hello command.\nDaniel says: Hello world!\n"
  end

  test "run error" do
    assert {:error, :missing_argument, %{name: :name, command: _}} = ExCLI.run(MyApp.SampleCLI, ["hello"])
  end

  test "run!" do
    assert capture_io(fn ->
      ExCLI.run!(MyApp.ComplexCLI, ["-v", "hello", "world", "--from", "Daniel"])
    end) == "Running hello command.\nDaniel says: Hello world!\n"
  end

  test "run! failure" do
    assert ("No command provided" <> _rest) = capture_io(fn ->
      ExCLI.run!(MyApp.SampleCLI, [], no_halt: true)
    end)
  end

  test "usage" do
    assert ("usage: " <> _rest) = ExCLI.usage(MyApp.ComplexCLI)
  end
end
