defmodule Lox.Ast.Unary do
  alias Lox.Ast.Node

  @enforce_keys []
  defstruct [:token, :value]
end