defmodule ExCLI.NormalizerTest do
  use ExUnit.Case

  alias ExCLI.Normalizer

  test "normalize args" do
    assert Normalizer.normalize(["foo", "bar"]) == [arg: "foo", arg: "bar"]
  end

  test "normalize short options" do
    assert Normalizer.normalize(["-ab", "-vvv"]) == [option: "a", option: "b"] ++ List.duplicate({:option, "v"}, 3)
  end

  test "normalize long options" do
    assert Normalizer.normalize(["--foo", "--bar"]) == [option: "foo", option: "bar"]
  end

  test "normalize" do
    expected = [option: "foo", arg: "foobar", option: "bar", option: "v", option: "v"]
    assert Normalizer.normalize(["--foo", "foobar", "--bar", "-vv"]) == expected
  end
end
