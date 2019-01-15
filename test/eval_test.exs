defmodule EvalTest do
  use ExUnit.Case
  doctest Eval

  def test_eval(input) do
    Lexer.tokenize(input)
    |> Parser.from_tokens
    |> Parser.parse_expression
    |> elem(1)
    |> Eval.eval
  end

  test "Test literal expression" do
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
      {"!true", false},
      {"2 > 3", false},
      {"2 >= 3", false},
      {"2 < 3", true},
      {"2 < 3", true},
      {"2 <= 3", true},
      {"3 == 3", true},
      {"2 == 3", false},
      {"2 != 3", true},
      {"nil == nil", true},
      {"nil == true", false},
      {"2 == nil", false},
    ]
    
    Enum.each(values, fn {input, expected} ->
      assert test_eval(input) == expected
    end)
  end

  test "eval concatenate strings expr" do
    assert test_eval(~s("hello" + " world")) == ~s("hello\"\" world")
  end

end