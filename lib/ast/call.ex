alias Lox.Ast.Call
alias Lox.Token

defmodule Lox.Ast.Call do
  @enforce_keys [:callee, :args]
  defstruct [:callee, :args]

  def get_name(%Call{callee: callee}), do: "#{callee}"
  def get_args(%Call{args: args}), do: args

  def arity(%Call{args: args} = call), do: length(args)
  
  def get_line(%Call{callee: callee} = function) do
    Token.get_line(callee)
  end
end
