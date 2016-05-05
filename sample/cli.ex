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
    option :from, help: "the sender of the hello"

    run do
      if from = options[:from] do
        IO.puts("#{from} says")
      end
      IO.puts("Hello #{name}")
    end
  end
end
