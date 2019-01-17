defmodule EnvironmentTest do
  alias Lox.{
    Environment,
    Token
  }

  use ExUnit.Case

  test "Environment: create" do
    assert Environment.new() == %Environment{map: %{}}
  end

  test "Environment: create with outer scope" do
    outer = %Environment{map: %{"a" => 2, "b" => 3}}
    assert Environment.new(outer) == %Environment{map: %{"a" => 2, "b" => 3}}
  end

  test "Environment: put" do
    var = "a"
    value = 2.0

    env =
    Environment.new()
    |> Environment.put(var, value)

    assert env == %Environment{map: %{"a" => 2}}
  end

  test "Environment: get" do
    var = "a"
    value = 2.0

    gv = 
    Environment.new()
    |> Environment.put(var, value)
    |> Environment.get(var)

    assert gv == value
  end

  test "Environment: get a variable that do not exists" do
    
    assert_raise EnvironmentError, "Undefined variable: 'abcd'", fn -> 
      var = Token.new(type: :STRING, lexeme: "abcd")
      Environment.new()
      |> Environment.get(var)
    end

  end

  test "Environment: contains" do
    var = "a"
    value = 2.0

    env = 
    Environment.new()
    |> Environment.put(var, value)

    assert Environment.contains(env, var) == true
  end
end