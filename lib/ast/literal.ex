alias Lox.Ast.Literal

defmodule Lox.Ast.Literal do
  @enforce_keys [:token]
  defstruct [:token]
end

defimpl String.Chars, for: Literal do
  def to_string(literal) do
    "#{Kernel.to_string(literal.token.lexeme)}"
  end
end
