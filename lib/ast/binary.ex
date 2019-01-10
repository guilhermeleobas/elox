defmodule Lox.Ast.Binary do

  @enforce_keys [:left, :operator, :right]
  defstruct [:left, :operator, :right]

end