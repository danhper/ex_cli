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
