# ExCLI

An Elixir library to create CLI applications.

## Roadmap

  - [ ] Command parser
  - [ ] Usage generation
  - [ ] Help command
  - [ ] Man page generation

## Installation

Add ex_cli to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:ex_cli, "~> 0.0.1"}]
end
```

## Usage

The basic usage is to use `ExCLI.DSL` to generate your app, and to parse
it using `ExCLI.process`. Here is a sample application:


```elixir
defmodule MyApp.SampleCLI do
  use ExCLI.DSL

  name "mycli"
  description "My CLI"
  long_description ~s"""
  This is my long description
  """

  command :hello do
    description "Greets the user"
    long_description """
    Gives a nice a warm greeting to whoever would listen
    """

    argument :name
    option :from, help: "the sender of hello"

    run context do
      if from = context.options[:from] do
        IO.write("#{from} says: ")
      end
      IO.puts("Hello #{context.name}!")
    end
  end
end

ExCLI.process(MyApp.SampleCLI, args, strict: false)
```
