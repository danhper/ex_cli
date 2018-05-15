defmodule MyApp.SampleCLIWithDefaultCommand do
  use ExCLI.DSL

  name "mycli"
  description "My CLI"
  long_description """
  This is my long description
  """
  default_command :hi

  option :verbose, help: "Increase the verbosity level", aliases: [:v], count: true

  command :hi do
    description "Greets the user"
    long_description """
    Gives a nice a warm greeting to whoever would listen
    """
    run _ do
      IO.puts("Hello world with defaults!")
    end
  end
end

