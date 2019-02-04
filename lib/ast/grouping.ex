defmodule Lox.Ast.Grouping do
  @enforce_keys [:expr]
  defstruct [:expr]

  defimpl String.Chars, for: Lox.Ast.Grouping do
    def to_string(grouping) do
      str = Kernel.to_string(grouping.expr)
      "(group #{str})"
    end
  end
end
