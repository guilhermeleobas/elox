defmodule EvalTest do
  use ExUnit.Case
  doctest Eval

  def test_eval(input) do
    Lexer.tokenize(input)
    |> Parser.parse
    |> hd
    |> Eval.eval
  end

  test "Test number literal expression" do
    values = [
      {"2", 2.0},
      {~s("hello"), "\"hello\""},
      {"nil", nil},
      {"true", true},
      {"false", false}
    ]
    
    Enum.each(values, fn {input, expected} ->
      assert test_eval(input) == expected
    end)
  end

  test "eval arithmetic expressions" do
    values = [
      {"2 + 3", 5.0},
      {"(5 - (3 - 1)) + -1", 2.0},
      {"!false", true},
      {"!true", false}
    ]
    
    Enum.each(values, fn {input, expected} ->
      assert test_eval(input) == expected
    end)
  end

  test "eval concatenate strings expr" do
    assert test_eval(~s("hello" + "world")) == ~s("hello world")
  end

end