defmodule MyApp.SampleCLIWithDefaultCommand do
  use ExCLI.DSL, mix_task: :with_default

  name "mycli"
  description "My CLI"
  long_description """
  This is my long description
  """

  option :verbose, help: "Increase the verbosity level", aliases: [:v], count: true

  default_command do
    run _ do
      IO.puts("Hello world with defaults!")
    end
  end
end

