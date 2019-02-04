defmodule Lox.Ast.Call do
  @enforce_keys [:callee, :args]
  defstruct [:callee, :args]
end
