defmodule Lox do
  @moduledoc """
  Documentation for Lox.
  """
  
  def read_file(filename) do
    File.read(filename)
  end
end
