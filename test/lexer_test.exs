defmodule LexerTest do
  use ExUnit.Case
  doctest Lexer

  test "single_char_op" do
    assert Lexer.single_char_op(["+"], []) == [Token.new(type: PLUS, lexeme: "+")] 
  end

  test "identifier" do
    token = Lexer.identifier_op(["a", "b", "c"], []) 
    assert token == [Token.new(type: IDENTIFIER, lexeme: "abc")] 
  end

  test "digit" do
    token = "12.34" |> Lexer.tokenize
    assert token == [Token.new(type: NUMBER, lexeme: "12.34")]
  end

  test "quotation mark" do
    assert Lexer.is_quote ("\"")
    assert Lexer.is_quote("h") == false
  end

  test "string tokenize" do
    token = "\"hello world\"" |> Lexer.tokenize
    assert token == [Token.new(type: STRING, lexeme: "\"hello world\"")]
  end

  test "equal equal" do
    token = "==" |> Lexer.tokenize
    assert token == [Token.new(type: EQUAL_EQUAL, lexeme: "==")]
  end

  test "equal" do
    token = "=" |> Lexer.tokenize
    assert token == [Token.new(type: EQUAL, lexeme: "=")]
  end

  test "bang" do
    token = "!" |> Lexer.tokenize
    assert token == [Token.new(type: BANG, lexeme: "!")]
  end

  test "bang equal" do
    token = "!=" |> Lexer.tokenize
    assert token == [Token.new(type: BANG_EQUAL, lexeme: "!=")]
  end

  test "less equal" do
    token = "<=" |> Lexer.tokenize
    assert token == [Token.new(type: LESS_EQUAL, lexeme: "<=")]
  end

end
