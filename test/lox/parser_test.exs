defmodule ParserTest do
  use ExUnit.Case
  doctest Parser

  test "a simple test" do
    Lexer.tokenize("2 == 2")
    |> IO.inspect 
    |> Parser.parse
    |> IO.inspect
  end
end