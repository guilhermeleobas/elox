defmodule Lox.Token do
  @doc """
    Encapsulate the notion of a Token
  """

  alias Lox.Token

  @enforce_keys [:type, :lexeme]
  defstruct [:type, :lexeme, :line]

  def new(type: type, lexeme: lexeme) do
    %Token{type: type, lexeme: lexeme, line: -1}
  end

  def new(type: type, lexeme: lexeme, line: line) do
    %Token{type: type, lexeme: lexeme, line: line}
  end
end

defimpl String.Chars, for: Lox.Token do
  def to_string(%Lox.Token{type: type, lexeme: lexeme} = token) do
    "#{lexeme}"
  end
end
