defmodule Lox.Ast.VarDecl do
  @enforce_keys [:name, :expr]
  defstruct [:name, :expr]
end
