defmodule ExCLI.DSL do
  defmacro __using__(_opts) do
    quote do
      import ExCLI.DSL
      @app %ExCLI.App{
        name: ExCLI.App.default_name(__MODULE__)
      }
      @before_compile unquote(__MODULE__)
      @command nil
    end
  end

  defmacro name(name) do
    quote bind_quoted: [name: name] do
      if @command do
        raise "name cannot be called inside a command block"
      else
        @app Map.put(@app, :name, name)
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
          @app Map.put(@app, key, value)
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
        @command Map.put(@command, :options, [{name, options} | @command.options])
      else
        @app Map.put(@app, :options, [{name, options} | @app.options])
      end
    end
  end

  defmacro run({context, _, _}, do: block) do
    quote bind_quoted: [context: context, block: Macro.escape(block, unquote: true)] do
      name = @command.name
      context = Macro.var(context, nil)
      def __run__(unquote(name), var!(unquote(context))) do
        unquote(block)
      end
    end
  end

  defmacro command(name, do: block) do
    quote do
      @command %ExCLI.Command{name: unquote(name)}
      unquote(block)
      @app Map.put(@app, :commands, [@command | @app.commands])
      @command nil
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc false
      def __app__ do
        @app
      end

      def process(args, options \\ []) do
        ExCLI.process(__MODULE__, args, options)
      end
    end
  end
end
