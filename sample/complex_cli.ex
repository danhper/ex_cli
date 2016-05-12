defmodule MyApp.ComplexCLI do
  use ExCLI.DSL, mix_task: Complex, escript: true

  name "mycli"
  description "My CLI"
  long_description """
  This is my long description
  """

  option :verbose, help: "Increase the verbosity level", aliases: [:v], count: true
  option :debug, help: "Set the debug mode", type: :boolean
  option :base_directory, help: "Set the base directory", metavar: "directory"
  option :log_file, help: "Set the log file", metavar: "file"

  command :hello do
    description "Greets the user"
    long_description """
    Gives a nice a warm greeting to whoever would listen
    """

    argument :name
    option :from, help: "the sender of hello"

    run context do
      if context.verbose >= 1 do
        IO.puts("Running hello command.")
      end
      if from = context[:from] do
        IO.write("#{from} says: ")
      end
      IO.puts("Hello #{context.name}!")
    end
  end

  command :speak do
    description "Gives a nice talk"
  end
end
