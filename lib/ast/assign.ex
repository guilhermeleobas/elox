defmodule Lox.Ast.Assign do

  @enforce_keys [:name, :value]
  defstruct [:name, :value]

  defimpl String.Chars, for: Lox.Ast.Assign do
    def to_string(assign) do
      "assign"
    end
  end
  
end