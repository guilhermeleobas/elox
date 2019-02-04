defmodule Lox.Ast.Function do
  @enforce_keys [:name, :args, :body]
  defstruct [:name, :args, :body]

  # @type t :: %Function{name : Token.() }
end
