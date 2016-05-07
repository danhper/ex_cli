defmodule ExCLI.Normalizer do
  @moduledoc false

  def normalize(args) do
    do_normalize(args, [])
  end

  defp do_normalize([], acc) do
    acc
    |> Enum.map(fn {type, value} ->
      {type, String.to_atom(value)}
    end)
    |> Enum.reverse
  end
  defp do_normalize(["--" <> option | rest], acc) do
    do_normalize(rest, [{:option, option} | acc])
  end
  defp do_normalize(["-" <> option | rest], acc) do
    options = String.split(option, "", trim: true)
    |> Enum.map(&({:option, &1}))
    |> Enum.reverse
    do_normalize(rest, options ++ acc)
  end
  defp do_normalize([arg | rest], acc) do
    do_normalize(rest, [{:arg, arg} | acc])
  end
end
