defmodule EvalError do
  defexception message: "Parser Error"
end

defmodule Eval do
  alias Lox.Ast.{
    Literal,
    Unary,
    Binary,
    Grouping
  }

  def eval(%Binary{} = expr) do
    left = eval(expr.left)
    right = eval(expr.right)

    result = 
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
      :NUMBER -> literal.value |> Float.parse |> elem(0)
      :STRING -> literal.value
      :FALSE -> false
      :TRUE -> true
      :NIL -> nil
    end
  end

end