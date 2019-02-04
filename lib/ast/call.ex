alias Lox.Ast.Call

defmodule Lox.Ast.Call do
  @enforce_keys [:callee, :args]
  defstruct [:callee, :args]

  def arity(%Call{args: args} = call) do
    length args
  end
end
