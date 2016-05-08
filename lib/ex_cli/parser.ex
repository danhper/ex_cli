defmodule ExCLI.Parser do
  @moduledoc false

  alias ExCLI.Argument

  def parse(app, args, opts \\ []) do
    with {:ok, normalized} <- ExCLI.Normalizer.normalize(args),
         {command, global_options, command_args} <- extract_command(normalized),
         {:ok, command} <- find_command(app, command),
         app_global_options = generate_options(app.options, opts),
         context = generate_context(app.options),
         {:ok, context} <- process_args(global_options, app_global_options, context) do
      context
    end
  end

  defp process_args([], _valid_arguments, context), do: {:ok, context}
  defp process_args([{type, name} | rest], valid_arguments, context) do
    case Map.fetch(valid_arguments, name) do
      {:ok, %Argument{arg_type: ^type} = arg} ->
        do_process_args(arg, rest, valid_arguments, context)
      _err ->
        {:error, unknown(type), name: name}
    end
  end

  defp unknown(key) do
    String.to_atom("unknown_#{key}")
  end

  defp do_process_args(arg, args, valid_arguments, context) do
    with {:ok, new_context, args_rest} <- arg.process.(arg, context, args) do
      process_args(args_rest, valid_arguments, new_context)
    end
  end

  defp extract_command(args) do
    case Enum.split_while(args, &match?({:option, _opt}, &1)) do
      {global_options, [{:arg, command} | command_args]} ->
        {command, global_options, command_args}
      {_options, []} ->
        {:error, :no_command, []}
    end
  end

  defp find_command(app, command_name) do
    case Enum.find(app.commands, &(&1.name == command_name)) do
      nil -> {:error, :command_not_found, name: command_name}
      command -> {:ok, command}
    end
  end

  defp generate_context(arguments, initial_context \\ %{}) do
    Enum.reduce arguments, initial_context, fn
      (%Argument{default: default} = arg, context) when not is_nil(default) ->
        Map.put_new(context, Argument.key(arg), default)
      (%Argument{count: true} = arg, context) ->
        Map.put_new(context, Argument.key(arg), 0)
      (%Argument{num: :infinity} = arg, context) ->
        Map.put_new(context, Argument.key(arg), [])
      (%Argument{num: n} = arg, context) when is_integer(n) and n > 1 ->
        Map.put_new(context, Argument.key(arg), [])
      (_arg, context) ->
        context
    end
  end

  defp generate_options(raw_app_options, opts) do
    Enum.reduce raw_app_options, %{}, fn option, acc ->
      acc = add_boolean_negation_option(acc, option, opts)
      processor = make_processor(option)
      processed_option = Map.put(option, :process, processor)
      acc = generate_aliases(acc, processed_option)
      put_option!(acc, option.name, processed_option)
    end
  end

  defp generate_aliases(app_options, option) do
    Enum.reduce option.aliases, app_options, fn(name, options) ->
      put_option!(options, name, option)
    end
  end

  defp put_option!(app_options, name, option) do
    if Map.has_key?(app_options, name) do
      raise ArgumentError, "duplicated key #{name}"
    else
      Map.put(app_options, name, option)
    end
  end

  defp add_boolean_negation_option(options, option, opts) do
    if option.type == :boolean and !opts[:no_boolean_negation] do
      key = String.to_atom("no_#{option.name}")
      Map.put(options, key, Map.put(option, :process, make_const_processor(false)))
    else
      options
    end
  end

  defp make_processor(option) do
    cond do
      option.process ->
        normalize_processor(option[:process])
      option.type == :boolean ->
        &process_boolean/3
      option.count ->
        &process_count/3
      is_integer(option.num) ->
        &process_list/3
      true ->
        &process_value/3
    end
  end

  defp normalize_processor({:const, value}) do
    make_const_processor(value)
  end
  defp normalize_processor(processor) when is_function(processor, 3) do
    processor
  end
  defp normalize_processor(processor) do
    raise ArgumentError, "invalid processor #{processor}"
  end

  defp process_list(option, context, args) do
    acc = Map.get(context, Argument.key(option), [])
    case do_process_list(option, args, acc) do
      {:ok, result, args} ->
        {:ok, Map.put(context, Argument.key(option), result), args}
      {:error, _reason, _details} = err ->
        err
    end
  end

  defp do_process_list(option, args, acc) do
    with {:ok, result, args} <- generate_list(option.num, args, acc),
         {:ok, transformed_result} <- transform_list(option.type, result) do
      {:ok, transformed_result, args}
    end |>
    case do
      {:ok, _result, _args} = res ->
        res
      {:error, reason, details} ->
        {:error, reason, [{:name, option.name} | details]}
    end
  end

  defp generate_list(n, [], acc) when n == 0 or n == :infinity do
    {:ok, acc, []}
  end
  defp generate_list(n, [], _acc) when is_integer(n) and n > 0 do
    {:error, :not_enough_args, []}
  end
  defp generate_list(n, [{:option, _option} | _rest] = args, acc)
    when n == 0 or n == :infinity do
    {:ok, acc, args}
  end
  defp generate_list(0, [{:arg, _arg} | _rest], _acc) do
    {:error, :too_many_args, []}
  end
  defp generate_list(:infinity, [{:arg, arg} | rest], acc) do
    generate_list(:infinity, rest, [arg | acc])
  end
  defp generate_list(n, [{:arg, arg} | rest], acc) when is_integer(n) do
    generate_list(n - 1, rest, [arg | acc])
  end

  defp transform_list(type, args), do: do_transform_list(type, args, [])
  defp do_transform_list(_type, [], acc), do: {:ok, acc}
  defp do_transform_list(type, [value | rest], acc) do
    case transform_value(value, type) do
      {:ok, transformed} -> do_transform_list(type, rest, [transformed | acc])
      :error -> {:error, :bad_argument, type: type}
    end
  end

  defp process_value(option, _context, []) do
    {:error, :arg_missing, name: option.name}
  end
  defp process_value(option, context, [value | rest]) do
    case transform_value(value, option.type) do
      {:ok, transformed} ->
        {:ok, Map.put(context, Argument.key(option), transformed), rest}
      :error ->
        {:error, :bad_argument, name: option.name, type: option.type}
    end
  end

  defp transform_value(value, :string), do: value
  defp transform_value(value, :integer), do: transform_num(value, Integer)
  defp transform_value(value, :float), do: transform_num(value, Flaot)
  defp transform_value(_value, type) do
    raise ArgumentError, "invalid type #{type}"
  end

  defp transform_num(value, mod) do
    case mod.parse(value) do
      {parsed, ""} -> {:ok, parsed}
      _            -> :error
    end
  end

  defp process_count(option, context, args) do
    current_value = Map.get(context, Argument.key(option), 0)
    {:ok, Map.put(context, Argument.key(option), current_value + 1), args}
  end

  defp process_boolean(option, context, [{:arg, "yes"} | rest]) do
    {:ok, Map.put(context, Argument.key(option), true), rest}
  end
  defp process_boolean(option, context, [{:arg, "no"} | rest]) do
    {:ok, Map.put(context, Argument.key(option), false), rest}
  end
  defp process_boolean(option, context, args) do
    {:ok, Map.put_new(context, Argument.key(option), true), args}
  end

  def make_const_processor(value) do
    fn option, context, args ->
      {:ok, Map.put(context, Argument.key(option), value), args}
    end
  end
end
