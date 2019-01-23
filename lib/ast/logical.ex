defmodule Lox.Ast.Logical do

  @enforce_keys [:left, :operator, :right]
  defstruct [:left, :operator, :right]
  
end