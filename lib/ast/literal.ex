defmodule Lox.Ast.Literal do

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

  defimpl String.Chars, for: Lox.Ast.Literal do
    def to_string(literal) do
      "#{Kernel.to_string(literal.value)}"
    end
  end
  
end