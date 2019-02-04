defmodule Lox.Ast.Block do
  @enforce_keys [:stmt_list]
  defstruct [:stmt_list]

  defimpl String.Chars, for: Lox.Ast.Block do
    def to_string(_block) do
      "block"
    end
  end
end
