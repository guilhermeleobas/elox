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

  def new() do
    %Environment{map: %{}}
  end

  def new(%Environment{} = outer) do
    %Environment{map: outer.map}
  end

  def get(%Environment{} = env, var) do
    case Map.get(env.map, var) do
      nil -> raise EnvironmentError, message: "Undefined variable: '#{var}'"
      value -> value
    end
  end

  def contains(%Environment{} = env, var) do
    Map.has_key?(env.map, var)
  end

  def put(%Environment{} = env, var, value) do
    %Environment{map: Map.put(env.map, var, value)}
  end

end