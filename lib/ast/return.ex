defmodule Lox.Ast.Return do

  @enforce_keys [:keyword, :expr]
  defstruct [:keyword, :expr]

end