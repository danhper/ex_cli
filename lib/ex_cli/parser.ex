defmodule ExCLI.Parser do
  @moduledoc false

  alias ExCLI.Argument

  def parse(app, args, opts \\ []) do
    with {:ok, normalized} <- ExCLI.Normalizer.normalize(args),
         {command, global_options, command_args} <- extract_command(normalized),
         {:ok, command} <- find_command(app, command),
         # FIXME: do this at compile time
         app_global_options = generate_options(app.options, opts),
         context = initialize_context(app.options),
         {:ok, context} <- process_args(global_options, nil, app_global_options, context),
         command_valid_options = generate_options(command.options, opts),
         context = initialize_context(app.options ++ app.commands, context),
         {:ok, context} <- process_args(command_args, command, command_valid_options, context) do
      context
    end
  end

  # TODO: check if context is valid (command arguments should be empty or have list: true) and reverse lists
  defp process_args([], _command,  _valid_options, context), do: {:ok, context}
  defp process_args([{:option, name} | rest], command, valid_options, context) do
    with {:ok, option} <- find_option(valid_options, name),
         {:ok, new_context, args_rest} <- option.process.(option, context, rest) do
      process_args(args_rest, command, valid_options, new_context)
    end
  end
  defp process_args([{:arg, value} | rest], command, valid_options, context) do
    with {:ok, arg, command} <- pop_argument(command, value),
         {:ok, value} <- transform_value(value, arg.type),
         new_context = put_value(context, arg, value) do
      process_args(rest, command, valid_options, new_context)
    end
  end

  defp find_option(valid_options, name) do
    case Map.fetch(valid_options, name) do
      {:ok, %Argument{arg_type: :option}} = res ->
        res
      _err ->
        {:error, :unknown_option, name: name}
    end
  end

  defp pop_argument(command, value) do
    case command.arguments do
      [] ->
        {:error, :too_many_args, value: value}
      [%Argument{list: true} = arg] ->
        {:ok, arg, command}
      [%Argument{} = arg | rest] ->
        {:ok, arg, Map.put(command, :arguments, rest)}
    end
  end

  defp extract_command(args) do
    case Enum.split_while(args, &match?({:option, _opt}, &1)) do
      {global_options, [{:arg, command} | command_args]} ->
        {String.to_atom(command), global_options, command_args}
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

  defp initialize_context(arguments, initial_context \\ %{}) do
    Enum.reduce arguments, initial_context, fn
      (%Argument{default: default} = arg, context) when not is_nil(default) ->
        Map.put_new(context, Argument.key(arg), default)
      (%Argument{count: true} = arg, context) ->
        Map.put_new(context, Argument.key(arg), 0)
      (%Argument{accumulate: true} = arg, context) ->
        Map.put_new(context, Argument.key(arg), [])
      (_arg, context) ->
        context
    end
  end

  defp generate_options(raw_app_options, opts) do
    Enum.reduce raw_app_options, %{}, fn option, acc ->
      acc = add_boolean_negation_option(acc, option, opts)
      processor = make_processor(option)
      # FIXME: no need to store process as an anonymous function
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

  defp process_value(arg, _context, []) do
    {:error, :arg_missing, name: arg.name}
  end
  defp process_value(arg, context, [value | rest]) do
    case transform_value(value, arg.type) do
      {:ok, transformed} ->
        {:ok, put_value(context, arg, transformed), rest}
      :error ->
        {:error, :bad_argument, name: arg.name, type: arg.type}
    end
  end

  defp put_value(context, arg, value) do
    key = Argument.key(arg)
    if arg.accumulate or arg.list do
      Map.put(context, key, [value | Map.fetch!(context,key)])
    else
      Map.put(context, key, value)
    end
  end

  defp transform_value("yes", :boolean), do: {:ok, true}
  defp transform_value("no", :boolean), do: {:ok, false}
  defp transform_value(value, :string), do: {:ok, value}
  defp transform_value(value, :integer), do: transform_num(value, Integer)
  defp transform_value(value, :float), do: transform_num(value, Float)
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
