defmodule ExCLI.Formatter.Error do
  @moduledoc false

  def format(error, details) when is_list(details) do
    format(error, Enum.into(details, %{}))
  end

  def format(:no_command, _details) do
    "No command provided"
  end

  def format(:unknown_command, %{name: name}) do
    "Unknown command '#{name}'"
  end

  def format(:missing_argument, %{name: name}) do
    "Missing argument '#{name}'"
  end

  def format(:missing_option, %{name: name}) do
    "Missing required option '#{name}'"
  end

  def format(:missing_option_argument, %{name: name}) do
    "No argument provided for '#{name}'"
  end

  def format(:unknown_option, %{name: name}) do
    "Unknown option '#{name}'"
  end

  def format(:too_many_arguments, %{value: value}) do
    "Unexpected argument '#{value}'"
  end

  def format(:bad_argument, %{name: name, type: type}) do
    "Could not convert '#{name}' to '#{type}'"
  end
end
