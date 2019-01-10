defmodule Lox.Ast.Unary do

  @enforce_keys [:token, :operator, :right]
  defstruct [:token, :operator, :right]

end