defmodule ExCLITest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  test "parse" do
    assert {:ok, :hello, %{name: "world"}} = ExCLI.parse(MyApp.SampleCLI, ["hello", "world"])
    assert {:ok, :hello, %{name: "world", verbose: 2}} = ExCLI.parse(MyApp.SampleCLI, ["-vv", "hello", "world"])
  end

  test "run" do
    assert capture_io(fn ->
      ExCLI.run(MyApp.SampleCLI, ["hello", "world"])
    end) == "Hello world!\n"

    assert capture_io(fn ->
      ExCLI.run(MyApp.SampleCLI, ["-vv", "hello", "world", "--from", "Daniel"])
    end) == "Running hello command.\nDaniel says: Hello world!\n"
  end

  test "run error" do
    assert ExCLI.run(MyApp.SampleCLI, ["hello"]) == {:error, :arg_missing, name: :name}
  end
end
