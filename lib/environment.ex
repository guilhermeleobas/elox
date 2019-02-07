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
  def get(_env, _key, opts \\ [type: "variable"])
  def get(nil, key, opts) do
    raise EnvironmentError, message: "Undefined #{opts[:type]}: '#{key}'"
  end

  def get(%Environment{} = env, key, opts) do
    case Map.get(env.inner, key) do
      nil -> 
        get(env.outer, key, opts)
      value -> 
        value
    end
  end

  ############################

  def contains(nil, _key) do
    false
  end

  def contains(%Environment{} = env, key) do
    case Map.has_key?(env.inner, key) do
      true ->
        true

      false ->
        contains(env.outer, key)
    end
  end

  ############################
  
  def update(env, key, value, opts \\ [type: "variable"])
  def update(nil, key, _value, opts) do
    raise EnvironmentError, message: "Undefined #{opts[:type]}: '#{key}'"
  end

  def update(%Environment{} = env, key, value, _opts) do
    case Map.has_key?(env.inner, key) do
      true ->
        %Environment{inner: Map.put(env.inner, key, value), outer: env.outer}

      false ->
        outer = update(env.outer, key, value)
        %Environment{inner: env.inner, outer: outer}
    end
  end

  ############################

  def put(%Environment{} = env, key, value) do
    %Environment{inner: Map.put(env.inner, key, value), outer: env.outer}
  end
end
