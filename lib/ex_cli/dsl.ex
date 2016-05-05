defmodule ExCLI.DSL do
  defmacro __using__(_opts) do
    quote do
      import ExCLI.DSL
      @cli %ExCLI.CLI{}
      @before_compile unquote(__MODULE__)
      @command nil
    end
  end

  defmacro name(name) do
    quote bind_quoted: [name: name] do
      if @command do
        raise "name cannot be called inside a command block"
      else
        @cli Map.put(@cli, :name, name)
      end
    end
  end

  Enum.each ~w(description long_description)a, fn key ->
    defmacro unquote(key)(value) do
      key = unquote(key)
      quote bind_quoted: [key: key, value: value] do
        if @command do
          @command Map.put(@command, key, value)
        else
          @cli Map.put(@cli, key, value)
        end
      end
    end
  end

  defmacro argument(name, options \\ []) do
    quote bind_quoted: [name: name, options: options] do
      if @command do
        @command Map.put(@command, :arguments, [{name, options} | @command.arguments])
      else
        raise "argument can only be used inside a command"
      end
    end
  end

  defmacro option(name, options \\ []) do
    quote bind_quoted: [name: name, options: options] do
      if @command do
        @command Map.put(@command, :options, [{name, options}, @command.options])
      else
        raise "option can only be used inside a command"
      end
    end
  end

  defmacro run(do: block) do
    quote bind_quoted: [block: Macro.escape(block, unquote: true)] do
      command = @command
      name = command.name
      args = Enum.map(command.arguments, &elem(&1, 0))
      ExCLI.DSL.__define_command__(name, args, block)
    end
  end

  defmacro __define_command__(name, args, block) do
    quote bind_quoted: [name: name, args: args, block: block] do
      arguments = Enum.map args, fn arg ->
        var = Macro.var(arg, nil)
        quote do
          var!(unquote(var))
        end
      end
      @doc false
      def __run__(unquote(name), unquote_splicing(arguments), var!(options)) do
        unquote(block)
      end
    end
  end

  defmacro command(name, do: block) do
    quote do
      @command %ExCLI.Command{name: unquote(name)}
      unquote(block)
      @cli Map.put(@cli, :commands, [@command | @cli.commands])
      @command nil
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc false
      def __cli__ do
        @cli
      end

      def process(args, options \\ []) do
        ExCLI.process(__MODULE__, args, options)
      end
    end
  end
end
