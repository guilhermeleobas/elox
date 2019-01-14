defmodule Lox.Ast.Binary do
  # token is the token operator
  # We need it in order to print the operator
  @enforce_keys [:token, :left, :operator, :right]
  defstruct [:token, :left, :operator, :right]

  defimpl String.Chars, for: Lox.Ast.Binary do
    def to_string(binary) do
      op = Kernel.to_string(binary.token)
      left = Kernel.to_string(binary.left)
      right = Kernel.to_string(binary.right)
      "(#{op} #{left} #{right})"
    end
  end
  
end