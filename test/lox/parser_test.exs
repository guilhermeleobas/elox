defmodule ParserTest do
  use ExUnit.Case
  doctest Parser

  test "a simple test" do
    Lexer.tokenize("(2 + 3) - 4")
    |> Parser.parse
    |> IO.inspect
  end
end