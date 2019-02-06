defmodule AstFunctionTest do
  use ExUnit.Case
  doctest Function
  
  alias Lox.{
    Lexer,
    Parser
  }

  alias Lox.Ast.{
    Call,
    Function,
    Stmt
  }

  defp get_ast(program) do
    program
    |> Lexer.tokenize
    |> Parser.parse
  end

  defp get_functions(ast), do: Enum.filter(ast, &match?(%Function{}, &1))
  defp get_calls(ast) do
    ast 
    |> Enum.filter(&match?(%Stmt{expr: %Call{}}, &1))
    |> Enum.map(fn x -> Map.get(x, :expr) end)
  end

  test "function name" do
    program = """
    fun average(a, b) {
      return (a + b)/2 ; 
    }
    fun sum(a, b, c, d) {
      return (a + b) + (c + d);
    }
    """
    functions = 
      get_ast(program)
      |> get_functions

    names = 
      functions
      |> Enum.map(fn x -> Kernel.to_string(x) end)
    
    assert names == ["<fn average>", "<fn sum>"]
  end

  test "test function decl/call arith method" do
    program = """
    fun sum(a, b, c) {
      return (a + b) + c;
    }

    sum(1, 2, 3, 4, 5);
    """
    
    ast = get_ast(program)

    functions = get_functions(ast)
    calls = get_calls(ast)

    assert functions |> hd |> Function.arity == 3
    assert calls |> hd |> Call.arity == 5
  end

end
