defmodule ParserTest do
  use ExUnit.Case
  doctest Parser

  test "Test parse expression" do
    assert Lexer.tokenize("-123 * (45.67)")
    |> Parser.parse
    |> hd
    |> to_string == "(* (- 123.0) (group 45.67))"
  end

  test "test expression to_string" do
    # https://github.com/munificent/craftinginterpreters/blob/master/test/expressions/parse.lox
    assert Lexer.tokenize("(5 - (3 - 1)) + -1")
    |> Parser.parse
    |> hd
    |> to_string == "(+ (group (- 5.0 (group (- 3.0 1.0)))) (- 1.0))"
  end
end