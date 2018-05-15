defmodule ExCLI.DSL do
  @moduledoc ~s"""
  A DSL to easily write CLI applications.

  This module should be used in a CLI specific module,
  and the macros should be used to define an application.

  ## Options

    * `escript`  - If set to `true`, it will generate a `main` function so that the module can be set as the `main_module` of an `escript`
    * `mix_task` - If specified, a mix task with the given name will be generated.


  ## Example

  ```elixir
  defmodule SampleCLI do
    use ExCLI.DSL, escript: true, mix_task: :sample

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
      aliases [:hi]
      description "Greets the user"
      long_description \"""
      Gives a nice a warm greeting to whoever would listen
      \"""

      argument :name
      option :from, help: "the sender of hello"

      run context do
        if context.verbose >= 1 do
          IO.puts("I am going to emit a greeting.")
        end
        if from = context[:from] do
          IO.write("\#{from} says: ")
        end
        IO.puts("Hello \#{context.name}!")
       end
    end
  end
  ```
  """

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts, module: __MODULE__] do
      import ExCLI.DSL

      @app %ExCLI.App{
        name: ExCLI.App.default_name(__MODULE__),
        opts: opts
      }
      @opts opts
      @before_compile module
      @command nil

      def name do
        @app.name
      end

      def default_command do
        @app.default_command
      end

      if opts[:escript] do
        def main(args) do
          ExCLI.run!(__MODULE__, args)
        end
      end
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

  @doc """
  Set the `default_command` of the application
  """
  @spec default_command(atom) :: any
  defmacro default_command(name) do
    quote bind_quoted: [name: name] do
      if @command do
        raise "default_command cannot be called inside a command block"
      else
        @app Map.put(@app, :default_command, name)
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
  Adds aliases to the command.

  Aliases can be used in place of the command's name on the command line.
  """
  @spec aliases([atom]) :: any
  defmacro aliases(names) do
    quote bind_quoted: [names: names] do
      if @command do
        @command Map.put(@command, :aliases, names)
      else
        raise "aliases can only be used inside a command"
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
      * `:boolean` - Will be parsed as a boolean (should be `"yes"` or `"no"`)
    * `:list`    - When true, the argument will accept multiple values and should be the last argument of the command
    * `:default` - The default value for the option
    * `:as`      - The key of the option in the context
    * `:metavar` - The name of the option argument displayed in the help

  """
  @spec argument(atom, Keyword.t) :: any
  defmacro argument(name, options \\ []) do
    quote bind_quoted: [name: name, options: options] do
      if @command do
        @command ExCLI.Command.add_argument(@command, name, options)
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

  Accepts the same options as `argument` except for `:list` and `:default`, as well as:

    * `:required`   - The command will fail if this option is not passed
    * `:aliases`    - A list of aliases (atoms) for the option
    * `:accumulate` - Will accumulate the options in a list
    * `:type`       - The type of the argument. See `argument/2` type documentation for available types.

      When the `type` option is `:boolean`, it will not consume the next argument
      except if it is `yes` or `no`. It will also accept `--no-OPTION` to negate the option.
    * `:default`    - The default value for the argument
    * `:as`         - The key of the argument in the context
    * `:process`    - A function to process the option, or an alias to an existing function.

      The following aliases are available

        * `{:const, value}` - Will store the value in the context

      When `:process` is a function, it must have the following signature

          process(arg :: ExCLI.Argument.t, context :: map, args :: [String.t]) :: {:ok, map, [String.t]} | {:error, atom, Keyword.t}

      where `arg` is the current argument (or option), `context` is a map with all the current parsed values and `args` are the current parsed arguments.

      The function should return either `{:ok, context, args}` with `context` and `args` updated on success, or `{:error, reason, details}` on failure.
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
  be accessible within the block. The map will have all the argument and option keys
  with the parsed values. It will not contain options without default if they were not given.

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

  @doc false
  def __define_mix_task__(mod, app, name) do
    app = Macro.escape(app)
    contents = quote do
      @moduledoc ExCLI.Formatter.Text.format(unquote(app), name: "mix #{unquote(name)}", mix: true)
      use Mix.Task
      def run(args) do
        ExCLI.run!(unquote(mod), args, name: "mix #{unquote(name)}")
      end
    end
    module = String.to_atom("Elixir.Mix.Tasks.#{name_to_module(name)}")
    Module.create(module, contents, __ENV__)
  end

  defp name_to_module(name) do
    name
    |> to_string()
    |> String.replace_leading("Elixir.", "")
    |> String.split(".")
    |> Enum.map(&Macro.camelize/1)
    |> Enum.join(".")
  end

  defmacro __before_compile__(_env) do
    quote do
      @app ExCLI.App.finalize(@app)

      @doc false
      def __app__ do
        @app
      end

      if task = @opts[:mix_task] do
        unquote(__MODULE__).__define_mix_task__(__MODULE__, @app, task)
      end
    end
  end
end
