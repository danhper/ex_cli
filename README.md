# ExCLI

Elixir library to build CLI applications.

## Installation

Add `ex_cli` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:ex_cli, "~> 0.0.1"}]
end
```

## Usage

The basic usage is to use `ExCLI.DSL` to define your CLI, and `ExCLI.run` to run it.
Here is a sample application:


```elixir
defmodule MyApp.SampleCLI do
  use ExCLI.DSL

  name "mycli"
  description "My CLI"
  long_description ~s"""
  This is my long description
  """

  option :verbose, count: true, aliases: [:v]

  command :hello do
    description "Greets the user"
    long_description """
    Gives a nice a warm greeting to whoever would listen
    """

    argument :name
    option :from, help: "the sender of hello"

    run context do
      if context.verbose > 0 do
        IO.puts("Running hello command")
      end
      if from = context[:from] do
        IO.write("#{from} says: ")
      end
      IO.puts("Hello #{context.name}!")
    end
  end
end

ExCLI.run(MyApp.SampleCLI)
```

Which can be used in the following way.

```
sample_cli hello -vv world --from me
```

## Roadmap

  * [x] Command parser
  * [ ] Usage generation
  * [ ] Help command
  * [ ] Command parser improvements
  * [ ] Man page generation

The command parser is now working and should be enough for a good number of tasks.

The next step is to get a pretty usage that can be shown to the user.

Then the goal will be to add a `help` command which can be used as `app help command` to show help about `command`.

When the usage and help parts are done, there are a few improvements that will be nice to have in the command parser:

  * the ability to set a default command
  * the ability to easily delegate a command to another module
  * fuzzy handling of command (i.e. `npm insta` will run `npm install`)

When all this is done, the last part will to generate documentation in man page and markdown formats, which will probably be done as a mix task.

## Contributing

Contributions are very welcome, feel free to open an issue or a PR.

I am also looking for a better name, ideas are welcome!
