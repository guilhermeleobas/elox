defmodule Lox.Ast.Unary do
  @enforce_keys [:token, :operator, :right]
  defstruct [:token, :operator, :right]

  defimpl String.Chars, for: Lox.Ast.Unary do
    def to_string(unary) do
      op = Kernel.to_string(unary.token)
      right = Kernel.to_string(unary.right)
      "(#{op} #{right})"
    end
  end
end
