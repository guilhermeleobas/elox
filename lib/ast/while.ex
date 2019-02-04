defmodule Lox.Ast.While do
  @enforce_keys [:cond_expr, :stmt_body]
  defstruct [:cond_expr, :stmt_body]
end
