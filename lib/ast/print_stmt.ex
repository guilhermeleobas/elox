defmodule Lox.Ast.PrintStmt do

  @enforce_keys [:expr]
  defstruct [:expr]

  defimpl String.Chars, for: Lox.Ast.PrintStmt do
    def to_string(stmt) do
      str = Kernel.to_string(stmt.expr)
      "print #{str}"
    end
  end
  
end