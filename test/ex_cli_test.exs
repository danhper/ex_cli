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
      ExCLI.run(MyApp.SampleCLI, ["hello", "world", "--from", "Daniel"])
    end) == "Daniel says: Hello world!\n"
  end
end
