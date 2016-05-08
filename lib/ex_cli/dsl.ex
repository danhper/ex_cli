defmodule ExCLI.DSL do
  @moduledoc ~s"""
  A DSL to easily write CLI applications.

  This module should be used in a CLI specific module,
  and the macros should be used to define an application.

  ## Example

  ```elixir
  defmodule SampleCLI do
    use ExCLI.DSL

    name "mycli"
    description "My CLI"
    long_description ""\"
    This is my long description
    \"""

    option :verbose,
      help: "Increase the verbosity level",
      aliases: [:v],
      count: true

    command :hello do
      description "Greets the user"
      long_description \"""
      Gives a nice a warm greeting to whoever would listen
      \"""

      argument :name
      option :from, help: "the sender of hello"

      run context do
        if context.options[:verbose] >= 1 do
          IO.puts("I am going to emit a greeting.")
        end
        if from = context.options[:from] do
          IO.write("\#{from} says: ")
        end
        IO.puts("Hello \#{context.name}!")
       end
    end
  end
  ```
  """

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

  @doc """
  Set the `name` of the application
  """
  @spec name(String.t | atom) :: any
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
    @doc """
    Set the `#{key}` of the application or the command
    """
    @spec unquote(key)(String.t) :: any
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

  @doc """
  Adds an argument to the command.

  The first argument should be an atom representing the name of the argument,
  which will be used to store the value in the generated application context.

  ## Options

    * `type`    - The type of the argument. Can be one of the following
      * `:integer` - Will be parsed as an integer
      * `:float`   - Will be parsed as a float
    * `metavar` - The name of the variable displayed in the usage
    * `default` - The default value for the argument
    * `num`     - The number of arguments that can be passed. Default to `1`. Can be an integer, a range, or `:infinity`. If the number of arguments that can be passed is greater than 1, the argument will be available as a list inside the context.
    * `:as`     - The key of the argument in the context
  """
  @spec argument(atom, Keyword.t) :: any
  defmacro argument(name, options \\ []) do
    quote bind_quoted: [name: name, options: options] do
      if @command do
        @command Map.put(@command, :arguments, [ExCLI.Argument.new(name, :arg, options) | @command.arguments])
      else
        raise "argument can only be used inside a command"
      end
    end
  end

  @doc """
  Adds an option to the command or the application or the command.

  The first argument should be an atom representing the name of the argument,
  which will be used to store the value in the generated application context.

  ## Options

  Accepts the same options as `argument`, as well as:

    * `required` - The command will fail if this option is not passed
    * `aliases`  - A list of aliases (atoms) for the option

  The `type` option also accepts `boolean`, which will not consume the next argument
  except if it is `yes` or `no`. Will also accept `--no-OPTION` to negate the option.
  """
  @spec option(atom, Keyword.t) :: any
  defmacro option(name, options \\ []) do
    quote bind_quoted: [name: name, options: options] do
      if @command do
        @command Map.put(@command, :options, [ExCLI.Argument.new(name, :option, options) | @command.options])
      else
        @app Map.put(@app, :options, [ExCLI.Argument.new(name, :option, options) | @app.options])
      end
    end
  end

  @doc """
  Defines the block to run when executing the command.

  The first argument is the context: a map containing the parsed argument, which will
  be accessible within the block. The map will have all the argument keys as well
  as the `:options` key containing the parsed options.

  See this module example for a sample usage.
  """
  @spec run(any, Keyword.t) :: any
  defmacro run({context, _, _}, do: block) do
    quote bind_quoted: [context: context, block: Macro.escape(block, unquote: true)] do
      name = @command.name
      context = Macro.var(context, nil)

      @doc false
      def __run__(unquote(name), var!(unquote(context))) do
        unquote(block)
      end
    end
  end

  @doc """
  Defines a command for the application

  The first argument should be an atom with the name of the command.
  """
  @spec command(atom, Keyword.t) :: any
  defmacro command(name, do: block) do
    quote do
      @command %ExCLI.Command{name: unquote(name)}
      unquote(block)
      @app Map.put(@app, :commands, [@command | @app.commands])
      @command nil
    end
  end

  defmacro __before_compile__(_env) do
    app_function = quote do
      @doc false
      def __app__ do
        @app
      end
    end
    fallback_run_clause = quote line: -1 do
      def __run__(command, _context) do
        raise ArgumentError, "command #{command} does not exist"
      end
    end
    quote do
      unquote(app_function)
      unquote(fallback_run_clause)
    end
  end
end
