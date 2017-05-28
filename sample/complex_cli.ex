defmodule MyApp.ComplexCLI do
  use ExCLI.DSL, mix_task: :complex, escript: true

  name "mycli"
  description "My CLI"
  long_description """
  This is my long description
  """

  option :v, help: "Increase the verbosity level", count: true, as: :verbose
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
    run _context do
      IO.puts "I can speak"
    end
  end

  command :talk do
    description "Talks to the user"
    run _context do
      IO.puts "I can talk"
    end
  end
end
