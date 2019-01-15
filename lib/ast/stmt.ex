defmodule Lox.Ast.Stmt do

  @enforce_keys [:expr]
  defstruct [:expr]

  defimpl String.Chars, for: Lox.Ast.Stmt do
    def to_string(stmt) do
      Kernel.to_string(stmt.expr)
    end
  end
  
end