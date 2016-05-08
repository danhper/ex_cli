defmodule ExCLI.NormalizerTest do
  use ExUnit.Case

  alias ExCLI.Normalizer

  test "normalize args" do
    assert Normalizer.normalize(["foo", "bar"]) == {:ok, [arg: :foo, arg: :bar]}
  end

  test "normalize short options" do
    assert Normalizer.normalize(["-ab", "-vvv"]) == {:ok, [option: :a, option: :b] ++ List.duplicate({:option, :v}, 3)}
  end

  test "normalize long options" do
    assert Normalizer.normalize(["--foo-bar", "--bar"]) == {:ok, [option: :foo_bar, option: :bar]}
  end

  test "normalize" do
    expected = [option: :foo, arg: :foobar, option: :bar, option: :v, option: :v]
    assert Normalizer.normalize(["--foo", "foobar", "--bar", "-vv"]) == {:ok, expected}
  end
end
