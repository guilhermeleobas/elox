alias Lox.Ast.Function

defmodule Lox.Ast.Function do
  @enforce_keys [:name, :args, :body]
  defstruct [:name, :args, :body]

  def arity(%Function{args: args} = _function) do
    length(args)
  end

  defimpl String.Chars do
    def to_string(literal) do
      "<fn #{literal.name}>"
    end
  end

end
