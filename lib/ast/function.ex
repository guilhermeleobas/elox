alias Lox.Ast.Function
alias Lox.Token

defmodule Lox.Ast.Function do
  @enforce_keys [:name, :args, :body]
  defstruct [:name, :args, :body]

  def get_name(%Function{name: name}), do: "#{name}"
  def get_args(%Function{args: args}), do: args
  def get_body(%Function{body: body}), do: body
  
  def arity(%Function{args: args}), do: length(args)
  def get_line(%Function{name: name}), do: Token.get_line(name)

  defimpl String.Chars do
    def to_string(function) do
      "<fn #{function.name}>"
    end
  end

  # defimpl Inspect do
  #   import Inspect.Algebra
  #   def inspect(fun, opts) do
  #     concat(["<fn #{fun.name}>"])
  #   end
  # end

end
