defmodule Lox.Ast.Literal do

  @enforce_keys [:token, :value]
  defstruct [:token, :value]

end

# defimpl String.Chars, for: Lox.Ast.Literal do
#   def to_string(literal) do
#     literal.value
#   end
# end