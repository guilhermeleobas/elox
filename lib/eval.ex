defmodule EvalError do
  defexception message: "Parser Error"
end

defmodule Eval do
  alias Lox.Ast.{
    Literal,
    Unary,
    Binary,
    Grouping,
    Stmt,
    PrintStmt,
    VarDecl,
  }

  alias Lox.{
    Lexer,
    Parser
  }

  defp eval(%Stmt{} = stmt) do
    eval(stmt.expr)
  end

  defp eval(%Binary{} = expr) do
    left = eval(expr.left)
    right = eval(expr.right)

    case expr.operator do
      :STAR -> left * right
      :SLASH -> left / right
      :MINUS -> left - right
      :PLUS -> 
        cond do
          is_number(left) && is_number(right) -> left + right
          is_binary(left) && is_binary(right) -> left <> right
          true -> raise EvalError, message: "Error while evaluating binary expr: #{expr}"
        end
      :GREATER -> left > right
      :GREATER_EQUAL -> left >= right
      :LESS -> left < right
      :LESS_EQUAL -> left <= right
      :EQUAL_EQUAL -> left == right
      :BANG_EQUAL -> left != right
    end
  end

  defp eval(%Unary{} = unary) do
    right = eval(unary.right)
    case unary.operator do
      :MINUS -> -right
      :BANG -> !right
    end
  end

  defp eval(%Grouping{} = grouping) do
    eval(grouping.expr)
  end

  defp eval(%Literal{} = literal) do
    case literal.token.type do
      :NUMBER -> literal.token.lexeme |> Float.parse |> elem(0)
      :STRING -> literal.token.lexeme
      :FALSE -> false
      :TRUE -> true
      :NIL -> nil
    end
  end

  defp eval(%VarDecl{} = vardecl) do
    
  end

  defp eval(%PrintStmt{} = print_stmt) do
    eval(print_stmt.expr)
    |> IO.write
  end

  def eval_program(program) do
    Lexer.tokenize(program)
    |> Parser.parse
    |> hd
    |> eval
  end


end