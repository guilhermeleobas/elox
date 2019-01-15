defmodule Lox.Ast.VarDecl do

  @enforce_keys [:name, :expr]
  defstruct [:name, :expr]

  defimpl String.Chars, for: Lox.Ast.VarDecl do
    def to_string(var) do
      "var"
    end
  end
  
end