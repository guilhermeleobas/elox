defmodule EnvironmentError do
  defexception message: "Lexer error"
end

defmodule Lox.Environment do

  alias Lox.{
    Token,
    Environment
  }

  @moduledoc """
    With :outer one can specify a map for the outer scope
    that the inner scope can inherit.

    If :outer is not specified, :outer is initialized with nil
    and :inner with an empty map 
  """
  defstruct [:outer, :inner]

  def new() do
    %Environment{outer: nil, inner: %{}}
  end

  def new(%Environment{} = outer) do
    %Environment{outer: outer, inner: %{}}
  end

  ############################

  def get(nil, var) do
    raise EnvironmentError, message: "Undefined variable: '#{var}'"
  end

  def get(%Environment{} = env, var) do
    case Map.get(env.inner, var) do
      nil -> get(env.outer, var)
      value -> value
    end
  end

  ############################

  def contains(nil, _var) do
    false
  end

  def contains(%Environment{} = env, var) do
    case Map.has_key?(env.inner, var) do
      true -> 
        true
      false ->
        contains(env.outer, var)
    end
  end

  ############################

  def update(nil, var, _value) do
    raise EnvironmentError, message: "Undefined variable: '#{var}'"
  end

  def update(%Environment{} = env, var, value) do
    case Map.has_key?(env.inner, var) do
      true ->
        %Environment{inner: Map.put(env.inner, var, value), outer: env.outer}
      false ->
        outer = update(env.outer, var, value)
        %Environment{inner: env.inner, outer: outer}
    end
  end

  ############################

  def put(%Environment{} = env, var, value) do
    %Environment{inner: Map.put(env.inner, var, value), outer: env.outer}
  end

end




