defmodule ExCLI.Parser do
  @moduledoc false

  alias ExCLI.{Argument, Command}


  def parse(app, args) do
    case do_parse(app, args) do
      {:ok, _command, _context} = result ->
        result
      {:error, reason, details} ->
        {:error, reason, Enum.into(details, %{})}
    end
  end

  defp do_parse(app, args) do
    with {:ok, command, context, args} <- parse_global(app, args) do
      parse_command(app, command, context, args)
    end
  end

  defp parse_global(app, args) do
    with {:ok, args} <- ExCLI.Normalizer.normalize(args),
         {:ok, args, context} <- process_args(args, nil, app.normalized_options, %{}),
         {command_name, args} <- extract_command(args),
         {:ok, command} <- find_command(app, command_name) do
      {:ok, command, context, args}
   end
  end

  defp parse_command(app, command, context, args) do
    with {:ok, [], context} <- process_args(args, command, command.normalized_options, context),
         context = add_defaults(context, app.options ++ command.arguments ++ command.options),
        :ok <- validate_context(app, command, context) do
      {:ok, command.name, finalize_context(context)}
    end |>
    case do
      {:error, reason, details}  ->
        {:error, reason, Keyword.put(details, :command, command)}
      {:ok, _name, _context} = result ->
        result
    end
  end

  defp process_args([], %ExCLI.Command{arguments: [%Argument{list: false, default: nil} = arg | _rest]}, _valid_options, _context) do
    {:error, :missing_argument, name: arg.name}
  end
  defp process_args([], _command, _valid_options, context), do: {:ok, [], context}
  defp process_args([{:option, name} | rest], command, valid_options, context) do
    with {:ok, option} <- find_option(valid_options, name),
         {:ok, new_context, args_rest} <- process_option(option, context, rest) do
      process_args(args_rest, command, valid_options, new_context)
    end
  end
  defp process_args([{:arg, _arg} | _rest] = args, nil, _valid_options, context), do: {:ok, args, context}
  defp process_args([{:arg, value} | rest], command, valid_options, context) do
    with {:ok, arg, command} <- pop_argument(command, value),
         {:ok, value} <- transform_arg_value(arg, value),
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
        {:error, :too_many_arguments, value: value}
      [%Argument{list: true} = arg] ->
        {:ok, arg, command}
      [%Argument{} = arg | rest] ->
        {:ok, arg, Map.put(command, :arguments, rest)}
    end
  end

  defp extract_command([]), do: {nil, []}
  defp extract_command([{:arg, command} | rest]), do: {String.to_atom(command), rest}

  defp find_command(app, command_name) do
    case Enum.find(app.commands, &(Command.match?(&1, command_name || app.default_command))) do
      nil ->
        if command_name == nil do
          {:error, :no_command, []}
        else
          {:error, :unknown_command, name: command_name}
        end
      command -> {:ok, command}
    end
  end

  defp add_defaults(context, arguments) do
    Enum.reduce arguments, context, fn
      (%Argument{default: default} = arg, context) when not is_nil(default) ->
        Map.put_new(context, Argument.key(arg), default)
      (%Argument{count: true} = arg, context) ->
        Map.put_new(context, Argument.key(arg), 0)
      (%Argument{accumulate: true} = arg, context) ->
        Map.put_new(context, Argument.key(arg), [])
      (%Argument{list: true} = arg, context) ->
        Map.put_new(context, Argument.key(arg), [])
      (_arg, context) ->
        context
    end
  end

  defp process_option(option, context, args) do
    cond do
      option.process ->
        call_processor(option, context, args)
      option.type == :boolean ->
        process_boolean(option, context, args)
      option.count ->
        process_count(option, context, args)
      true ->
        process_value(option, context, args)
    end
  end

  defp call_processor(%Argument{process: {:const, value}} = option, context, args) do
    {:ok, Map.put(context, Argument.key(option), value), args}
  end
  defp call_processor(%Argument{process: processor} = option, context, args) when is_function(processor, 3) do
    processor.(option, context, args)
  end
  defp call_processor(%Argument{process: processor}, _, _) do
    raise ArgumentError, "invalid processor #{inspect(processor)}"
  end

  defp process_value(arg, _context, []) do
    {:error, :missing_option_argument, name: arg.name}
  end
  defp process_value(arg, _context, [{:option, _option} | _rest]) do
    {:error, :missing_option_argument, name: arg.name}
  end
  defp process_value(arg, context, [{:arg, value} | rest]) do
    with {:ok, transformed} <- transform_arg_value(arg, value) do
      {:ok, put_value(context, arg, transformed), rest}
    end
  end

  defp put_value(context, arg, value) do
    key = Argument.key(arg)
    if arg.accumulate or arg.list do
      Map.put(context, key, [value | Map.get(context, key, [])])
    else
      Map.put(context, key, value)
    end
  end

  defp transform_arg_value(arg, value) do
    case transform_value(value, arg.type) do
      {:ok, _transformed} = res ->
        res
      :error ->
        {:error, :bad_argument, name: arg.name, type: arg.type}
    end
  end

  defp transform_value("yes", :boolean), do: {:ok, true}
  defp transform_value("no", :boolean), do: {:ok, false}
  defp transform_value(_, :boolean), do: :error
  defp transform_value(value, :string), do: {:ok, value}
  defp transform_value(value, :integer), do: transform_num(value, Integer)
  defp transform_value(value, :float), do: transform_num(value, Float)
  defp transform_value(_value, type) do
    raise ArgumentError, "invalid type #{inspect(type)}"
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

  defp validate_context(app, command, context) do
    with :ok <- validate_options(app.options, context) do
      validate_options(command.options, context)
    end
  end

  defp validate_options([], _context), do: :ok
  defp validate_options([option | rest], context) do
    if option.required and not Map.has_key?(context, Argument.key(option)) do
      {:error, :missing_option, name: option.name}
    else
      validate_options(rest, context)
    end
  end

  defp finalize_context(context) do
    context
    |> Enum.map(fn
        {k, v} when is_list(v) -> {k, Enum.reverse(v)}
        kv -> kv
      end)
    |> Enum.into(%{})
  end
end
