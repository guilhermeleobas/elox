defmodule ParserTest do
  alias Lox.Ast.{
    Literal,
    Binary,
    PrintStmt,
    VarDecl
  }

  alias Lox.{
    Token,
    Lexer,
    Parser
  }

  use ExUnit.Case
  doctest Parser

  test "Variable declaration" do
    values = [
      {"var a;", [%VarDecl{expr: nil, name: Token.new(type: :IDENTIFIER, lexeme: "a")}]},
      {"var b = 3;",
       [
         %VarDecl{
           name: Token.new(type: :IDENTIFIER, lexeme: "b"),
           expr: %Literal{token: Token.new(type: :NUMBER, lexeme: "3.0")}
         }
       ]}
    ]

    Enum.each(values, fn {input, output} ->
      result =
        Lexer.tokenize(input)
        |> Parser.parse()

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
      {"nil", Token.new(type: :NIL, lexeme: "nil")}
    ]

    Enum.each(values, fn {input, output} ->
      result =
        Lexer.tokenize(input)
        |> Parser.from_tokens()
        |> Parser.parse_expression()
        |> elem(1)

      assert result.token == output
    end)
  end

  test "Test parse expression" do
    assert Lexer.tokenize("-123 * (45.67) ;")
           |> Parser.parse()
           |> hd
           |> to_string == "(* (- 123.0) (group 45.67))"
  end

  test "test expression to_string" do
    # https://github.com/munificent/craftinginterpreters/blob/master/test/expressions/parse.lox
    assert Lexer.tokenize("(5 - (3 - 1)) + -1 ;")
           |> Parser.parse()
           |> hd
           |> to_string == "(+ (group (- 5.0 (group (- 3.0 1.0)))) (- 1.0))"
  end

  test "parse print statement" do
    values = [
      {"print true ;",
       [
         %PrintStmt{
           expr: %Literal{
             token: Token.new(type: :TRUE, lexeme: "true")
           }
         }
       ]},
      {"print 2 + 3 ;",
       [
         %PrintStmt{
           expr: %Binary{
             left: %Literal{token: Token.new(type: :NUMBER, lexeme: "2.0")},
             right: %Literal{token: Token.new(type: :NUMBER, lexeme: "3.0")},
             token: Token.new(type: :PLUS, lexeme: "+"),
             operator: :PLUS
           }
         }
       ]},
      {"print 2 + 3; print true ;",
       [
         %Lox.Ast.PrintStmt{
           expr: %Lox.Ast.Binary{
             left: %Lox.Ast.Literal{
               token: Token.new(type: :NUMBER, lexeme: "2.0")
             },
             operator: :PLUS,
             right: %Lox.Ast.Literal{
               token: Token.new(type: :NUMBER, lexeme: "3.0")
             },
             token: Token.new(type: :PLUS, lexeme: "+")
           }
         },
         %Lox.Ast.PrintStmt{
           expr: %Lox.Ast.Literal{
             token: Token.new(type: :TRUE, lexeme: "true")
           }
         }
       ]}
    ]

    Enum.each(values, fn {input, output} ->
      result =
        Lexer.tokenize(input)
        |> Parser.parse()

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
      %Lox.Ast.VarDecl{
        expr: %Lox.Ast.Literal{
          token: %Token{lexeme: "2.0", line: 1, type: :NUMBER}
        },
        name: %Token{lexeme: "a", line: 1, type: :IDENTIFIER}
      },
      %Lox.Ast.VarDecl{
        expr: nil,
        name: %Token{lexeme: "b", line: 2, type: :IDENTIFIER}
      },
      %Lox.Ast.Stmt{
        expr: %Lox.Ast.Assign{
          name: %Token{lexeme: "b", line: 3, type: :IDENTIFIER},
          expr: %Lox.Ast.Literal{
            token: %Token{lexeme: "a", line: 3, type: :IDENTIFIER}
          }
        }
      }
    ]

    assert tokens ==
             Lexer.tokenize(program)
             |> Parser.parse()
  end

  test "parse block" do
    program = """
    {
      var a = "Hello World!";
    }
    """

    tokens = [
      %Lox.Ast.Block{
        stmt_list: [
          %Lox.Ast.VarDecl{
            expr: %Lox.Ast.Literal{
              token: %Lox.Token{lexeme: "\"Hello World!\"", line: 2, type: :STRING}
            },
            name: %Lox.Token{lexeme: "a", line: 2, type: :IDENTIFIER}
          }
        ]
      }
    ]

    assert tokens ==
             Lexer.tokenize(program)
             |> Parser.parse()
  end

  test "parse curry function call " do
    program = """
    average(1, 2)(3, 4)()("abc", 7); 
    """

    tokens = [
      %Lox.Ast.Stmt{
        expr: %Lox.Ast.Call{
          args: [
            %Lox.Ast.Literal{
              token: Token.new(lexeme: "\"abc\"", type: :STRING)
            },
            %Lox.Ast.Literal{
              token: Token.new(lexeme: "7.0", type: :NUMBER)
            }
          ],
          callee: %Lox.Ast.Call{
            args: [],
            callee: %Lox.Ast.Call{
              args: [
                %Lox.Ast.Literal{
                  token: Token.new(lexeme: "3.0", type: :NUMBER)
                },
                %Lox.Ast.Literal{
                  token: Token.new(lexeme: "4.0", type: :NUMBER)
                }
              ],
              callee: %Lox.Ast.Call{
                args: [
                  %Lox.Ast.Literal{
                    token: Token.new(lexeme: "1.0", type: :NUMBER)
                  },
                  %Lox.Ast.Literal{
                    token: Token.new(lexeme: "2.0", type: :NUMBER)
                  }
                ],
                callee: Token.new(lexeme: "average", type: :IDENTIFIER)
              }
            }
          }
        }
      }
    ]

    assert tokens ==
             Lexer.tokenize(program)
             |> Parser.parse()
  end

  test "parse function call with more than 8 arguments" do
    program = "average(1, 2, 3, 4, 5, 6, 7, 8, 9);"

    assert_raise ParserError, "Function call to 'average' with more than 8 arguments", fn ->
      Lexer.tokenize(program)
      |> Parser.parse()
    end
  end

  test "parse function declaration" do
    program = """
    fun sum(a, b, c){
      var d = (a + b) + c;
      return d;
    }
    """

    tokens = [
      %Lox.Ast.Function{
        args: [
          %Lox.Token{lexeme: "a", line: 1, type: :IDENTIFIER},
          %Lox.Token{lexeme: "b", line: 1, type: :IDENTIFIER},
          %Lox.Token{lexeme: "c", line: 1, type: :IDENTIFIER}
        ],
        body: %Lox.Ast.Block{
          stmt_list: [
            %Lox.Ast.VarDecl{
              expr: %Lox.Ast.Binary{
                left: %Lox.Ast.Grouping{
                  expr: %Lox.Ast.Binary{
                    left: %Lox.Ast.Literal{
                      token: %Lox.Token{lexeme: "a", line: 2, type: :IDENTIFIER}
                    },
                    operator: :PLUS,
                    right: %Lox.Ast.Literal{
                      token: %Lox.Token{lexeme: "b", line: 2, type: :IDENTIFIER}
                    },
                    token: %Lox.Token{lexeme: "+", line: 2, type: :PLUS}
                  }
                },
                operator: :PLUS,
                right: %Lox.Ast.Literal{
                  token: %Lox.Token{lexeme: "c", line: 2, type: :IDENTIFIER}
                },
                token: %Lox.Token{lexeme: "+", line: 2, type: :PLUS}
              },
              name: %Lox.Token{lexeme: "d", line: 2, type: :IDENTIFIER}
            },
            %Lox.Ast.Return{
              expr: %Lox.Ast.Literal{
                token: %Lox.Token{lexeme: "d", line: 3, type: :IDENTIFIER}
              },
              keyword: %Lox.Token{lexeme: "return", line: 3, type: :RETURN}
            }
          ]
        },
        name: %Lox.Token{lexeme: "sum", line: 1, type: :IDENTIFIER}
      }
    ]

    assert tokens ==
             Lexer.tokenize(program)
             |> Parser.parse()
  end

  test "parse function with more than 8 arguments" do
    program = """
    fun sum(a, b, c, d, e, f, g, h, i, j, k, l){
      return a;
    }
    """

    assert_raise ParserError, "Function 'sum' declared with more than 8 arguments", fn ->
      Lexer.tokenize(program)
      |> Parser.parse()
    end
  end
end
