defmodule ExCLI.UtilTest do
  use ExUnit.Case

  alias ExCLI.Util

  test "pretty join with infinite width" do
    list = List.duplicate("foo", 20)
    assert Util.pretty_join(list, width: :infinity) == Enum.join(list, " ")
  end

  test "pretty join" do
    assert Util.pretty_join(~w(foo bar baz), width: 8) == "foo bar\nbaz"
  end
end
