defmodule Lox.Ast.Literal do

  @enforce_keys [:token]
  defstruct [:token]

  defimpl String.Chars, for: Lox.Ast.Literal do
    def to_string(literal) do
      "#{Kernel.to_string(literal.token.lexeme)}"
    end
  end
  
end