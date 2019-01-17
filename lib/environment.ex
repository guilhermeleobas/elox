defmodule EnvironmentError do
  defexception message: "Lexer error"
end

defmodule Lox.Environment do

  alias Lox.{
    Token,
    Environment
  }

  @moduledoc """
    With :map one can specify a map for the outer scope
    that the inner scope can inherit.

    If :map is not specified, the environment is initialized
    with an empty map.
  """
  
  defstruct [:map]

  defp from_map(%{} = map) do
    %Environment{map: map}
  end

  def new() do
    %Environment{map: %{}}
  end

  def new(%Environment{} = outer) do
    %Environment{map: outer.map}
  end

  def get(%Environment{} = env, %Token{} = var) do
    case Map.get(env.map, var.lexeme) do
      nil -> raise EnvironmentError, message: "Undefined variable: '#{var.lexeme}'"
      value -> value
    end
  end

  def put(%Environment{} = env, %Token{} = var, value) do
    Map.put(env.map, var.lexeme, value)
    |> from_map
  end

end