defmodule LexerTest do
  alias Lox.{
    Token,
    Lexer
  }

  use ExUnit.Case
  doctest Lexer

  test "single_char_op" do
    assert hd(Lexer.tokenize("+")) == Token.new(type: :PLUS, lexeme: "+")
  end

  test "identifier" do
    token = Lexer.tokenize("abc")
    assert hd(token) == Token.new(type: :IDENTIFIER, lexeme: "abc")
  end

  test "reserved identifiers" do
    assert hd(Lexer.tokenize("and")) == Token.new(type: :AND, lexeme: "and")
    assert hd(Lexer.tokenize("class")) == Token.new(type: :CLASS, lexeme: "class")
    assert hd(Lexer.tokenize("else")) == Token.new(type: :ELSE, lexeme: "else")
    assert hd(Lexer.tokenize("false")) == Token.new(type: :FALSE, lexeme: "false")
    assert hd(Lexer.tokenize("fun")) == Token.new(type: :FUN, lexeme: "fun")
    assert hd(Lexer.tokenize("for")) == Token.new(type: :FOR, lexeme: "for")
    assert hd(Lexer.tokenize("if")) == Token.new(type: :IF, lexeme: "if")
    assert hd(Lexer.tokenize("nil")) == Token.new(type: :NIL, lexeme: "nil")
    assert hd(Lexer.tokenize("or")) == Token.new(type: :OR, lexeme: "or")
    assert hd(Lexer.tokenize("print")) == Token.new(type: :PRINT, lexeme: "print")
    assert hd(Lexer.tokenize("return")) == Token.new(type: :RETURN, lexeme: "return")
    assert hd(Lexer.tokenize("super")) == Token.new(type: :SUPER, lexeme: "super")
    assert hd(Lexer.tokenize("this")) == Token.new(type: :THIS, lexeme: "this")
    assert hd(Lexer.tokenize("true")) == Token.new(type: :TRUE, lexeme: "true")
    assert hd(Lexer.tokenize("var")) == Token.new(type: :VAR, lexeme: "var")
    assert hd(Lexer.tokenize("while")) == Token.new(type: :WHILE, lexeme: "while")
  end

  test "digit" do
    token = "12.34" |> Lexer.tokenize()
    assert hd(token) == Token.new(type: :NUMBER, lexeme: "12.34")
  end

  test "single digit" do
    token = Lexer.tokenize("1234")
    assert hd(token) == Token.new(type: :NUMBER, lexeme: "1234.0")
  end

  @tag :invalid
  test "invalid digit" do
    assert_raise LexerError, "Error creating token for number 1234. on line 1", fn ->
      Lexer.tokenize("1234.")
    end
  end

  test "quotation mark" do
    assert Lexer.is_quote("\"")
    assert Lexer.is_quote("h") == false
  end

  test "string tokenize" do
    token = "\"hello world\"" |> Lexer.tokenize()
    assert hd(token) == Token.new(type: :STRING, lexeme: "\"hello world\"")
  end

  test "empty string" do
    token = ~s(" ") |> Lexer.tokenize()
    assert hd(token) == Token.new(type: :STRING, lexeme: ~s(" "))
  end

  test "equal equal" do
    token = "==" |> Lexer.tokenize()
    assert hd(token) == Token.new(type: :EQUAL_EQUAL, lexeme: "==")
  end

  test "equal" do
    token = "=" |> Lexer.tokenize()
    assert hd(token) == Token.new(type: :EQUAL, lexeme: "=")
  end

  test "bang" do
    token = "!" |> Lexer.tokenize()
    assert hd(token) == Token.new(type: :BANG, lexeme: "!")
  end

  test "bang equal" do
    token = "!=" |> Lexer.tokenize()
    assert hd(token) == Token.new(type: :BANG_EQUAL, lexeme: "!=")
  end

  test "less equal" do
    token = "<=" |> Lexer.tokenize()
    assert hd(token) == Token.new(type: :LESS_EQUAL, lexeme: "<=")
  end

  test "comment" do
    program = "// This is a comment"
    assert Lexer.tokenize(program) == [Token.new(type: :EOF, lexeme: "")]
  end

  test "small example" do
    program = """
    // this is a comment
    (( )){} // grouping stuff
    !*+-/=<> <= == // operators
    """

    assert Lexer.tokenize(program) == [
             %Token{lexeme: "(", line: 2, type: :LEFT_PAREN},
             %Token{lexeme: "(", line: 2, type: :LEFT_PAREN},
             %Token{lexeme: ")", line: 2, type: :RIGHT_PAREN},
             %Token{lexeme: ")", line: 2, type: :RIGHT_PAREN},
             %Token{lexeme: "{", line: 2, type: :LEFT_BRACE},
             %Token{lexeme: "}", line: 2, type: :RIGHT_BRACE},
             %Token{lexeme: "!", line: 3, type: :BANG},
             %Token{lexeme: "*", line: 3, type: :STAR},
             %Token{lexeme: "+", line: 3, type: :PLUS},
             %Token{lexeme: "-", line: 3, type: :MINUS},
             %Token{lexeme: "/", line: 3, type: :SLASH},
             %Token{lexeme: "=", line: 3, type: :EQUAL},
             %Token{lexeme: "<", line: 3, type: :LESS},
             %Token{lexeme: ">", line: 3, type: :GREATER},
             %Token{lexeme: "<=", line: 3, type: :LESS_EQUAL},
             %Token{lexeme: "==", line: 3, type: :EQUAL_EQUAL},
             %Token{lexeme: "", line: 4, type: :EOF}
           ]
  end
end
