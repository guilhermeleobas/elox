defmodule Lox.Ast.If do

  @enforce_keys [:cond_expr, :then_stmt, :else_stmt]
  defstruct [:cond_expr, :then_stmt, :else_stmt]

  defimpl String.Chars, for: Lox.Ast.If do
    def to_string(_if) do
      "if"
    end
  end
  
end