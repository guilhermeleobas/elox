defmodule ParserTest do
  alias Lox.Ast.{
    Literal,
    Binary,
    Stmt,
    PrintStmt,
    VarDecl
  }

  alias Lox.{
    Token,
    Lexer,
    Parser,
  }

  use ExUnit.Case
  doctest Parser

  test "Variable declaration" do
    values = [
      {"var a;", [%VarDecl{expr: nil, name: Token.new(type: :IDENTIFIER, lexeme: "a") }]},
      {"var b = 3;", [%VarDecl{ 
        name: Token.new(type: :IDENTIFIER, lexeme: "b"),
        expr: %Literal{token: Token.new(type: :NUMBER, lexeme: "3.0")}
        }]
      }
    ]

    Enum.each(values, fn {input, output} ->
      result =
      Lexer.tokenize(input)
      |> Parser.parse

      assert result == output
    end)
  end

  test "Literals" do
    values = [
      {"\"Hello world\"", Token.new(type: :STRING, lexeme: "\"Hello world\"")},
      {"2.0", Token.new(type: :NUMBER, lexeme: "2.0")},
      {"true", Token.new(type: :TRUE, lexeme: "true")},
      {"false", Token.new(type: :FALSE, lexeme: "false")},
      {"this", Token.new(type: :THIS, lexeme: "this")},
      {"nil", Token.new(type: :NIL, lexeme: "nil")},
    ]

    Enum.each(values, fn {input, output} ->
      result = 
      Lexer.tokenize(input)
      |> Parser.from_tokens
      |> Parser.parse_expression
      |> elem(1)
      
      assert result.token == output

    end)
  end

  test "Test parse expression" do
    assert Lexer.tokenize("-123 * (45.67) ;")
    |> Parser.parse
    |> hd
    |> to_string == "(* (- 123.0) (group 45.67))"
  end

  test "test expression to_string" do
    # https://github.com/munificent/craftinginterpreters/blob/master/test/expressions/parse.lox
    assert Lexer.tokenize("(5 - (3 - 1)) + -1 ;")
    |> Parser.parse
    |> hd
    |> to_string == "(+ (group (- 5.0 (group (- 3.0 1.0)))) (- 1.0))"
  end

  test "parse print statement" do
    values = [
      {"print true ;", 
        [%PrintStmt{
                  expr: %Literal{
                    token: %Token{lexeme: "true", line: -1, type: :TRUE}
                  }
                }]
      },
      {"print 2 + 3 ;",
        [%PrintStmt{
                  expr: %Binary{
                    left: %Literal{token: Token.new(type: :NUMBER, lexeme: "2.0")},
                    right: %Literal{token: Token.new(type: :NUMBER, lexeme: "3.0")},
                    token: Token.new(type: :PLUS, lexeme: "+"),
                    operator: :PLUS
                  }
                }]
      },
      {"print 2 + 3; print true ;", 
        [%Lox.Ast.PrintStmt{
          expr: %Lox.Ast.Literal{
            token: %Token{lexeme: "true", line: -1, type: :TRUE},
          }
        },
        %Lox.Ast.PrintStmt{
          expr: %Lox.Ast.Binary{
            left: %Lox.Ast.Literal{
              token: %Token{lexeme: "2.0", line: -1, type: :NUMBER},
            },
            operator: :PLUS,
            right: %Lox.Ast.Literal{
              token: %Token{lexeme: "3.0", line: -1, type: :NUMBER},
            },
            token: %Token{lexeme: "+", line: -1, type: :PLUS}
          }
        }
      ]}
    ]

    Enum.each(values, fn {input, output} ->
      result = 
      Lexer.tokenize(input)
      |> Parser.parse
      assert result == output
    end)

  end

  test "parse assignment" do
    program = """
    var a = 2;
    var b;
    b = a;
    """

    tokens = [
      %Lox.Ast.Stmt{
        expr: %Lox.Ast.Assign{
          name: %Token{lexeme: "b", line: -1, type: :IDENTIFIER},
          value: %Lox.Ast.Literal{
            token: %Token{lexeme: "a", line: -1, type: :IDENTIFIER}
          }
        }
      },
      %Lox.Ast.VarDecl{
        expr: nil,
        name: %Token{lexeme: "b", line: -1, type: :IDENTIFIER}
      },
      %Lox.Ast.VarDecl{
        expr: %Lox.Ast.Literal{
          token: %Token{lexeme: "2.0", line: -1, type: :NUMBER}
        },
        name: %Token{lexeme: "a", line: -1, type: :IDENTIFIER}
      }
    ]
    
    assert tokens == 
    Lexer.tokenize(program)
    |> Parser.parse
    
  end

end