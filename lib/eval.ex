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
  }

  defp check_number_operands(operator, left, right) do
    if !(is_number(left) && is_number(right)) do
      raise EvalError, message: "Operands must be a number on #{operator}"
    else
      true
    end
  end

  def eval(%Stmt{} = stmt) do
    eval(stmt.expr)
  end

  def eval(%Binary{} = expr) do
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

  def eval(%Unary{} = unary) do
    right = eval(unary.right)
    case unary.operator do
      :MINUS -> -right
      :BANG -> !right
    end
  end

  def eval(%Grouping{} = grouping) do
    eval(grouping.expr)
  end

  def eval(%Literal{} = literal) do
    case literal.token.type do
      :NUMBER -> literal.token.lexeme |> Float.parse |> elem(0)
      :STRING -> literal.token.lexeme
      :FALSE -> false
      :TRUE -> true
      :NIL -> nil
    end
  end

end