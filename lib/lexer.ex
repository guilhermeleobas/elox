
tokens = %{
  # Single-character tokens
  LEFT_PAREN: 0,
  RIGHT_PAREN: 1,
  LEFT_BRACE: 2,
  RIGHT_BRACE: 3,
  COMMA: 4,
  DOT: 5,
  MINUS: 6,
  PLUS: 7,
  SEMICOLON: 8,
  SLASH: 9,
  STAR: 10,

  # One or two characters tokens
  BANG: 11,
  BANG_EQUAL: 12,
  EQUAL: 13,
  EQUAL_EQUAL: 14,
  GREATER: 15,
  GREATER_EQUAL: 16,
  LESS: 17,
  LESS_EQUAL: 18,

  # Literals
  IDENTIFIER: 19,
  STRING: 20,
  NUMBER: 21,

  # Keywords
  AND: 22,
  CLASS: 23,
  ELSE: 24,
  FALSE: 25,
  FUN: 26,
  FOR: 27,
  IF: 28,
  NIL: 29,
  OR: 30,
  PRINT: 31,
  RETURN: 32,
  SUPER: 33,
  THIS: 34,
  TRUE: 35,
  VAR: 36,
  WHILE: 37,

  EOF: 38,
}

defmodule Lexer do

  def error(message) do
    raise message 
  end

  def is_digit(c) do
    c >= "0" && c <= "9"
  end

  def is_alpha(c) do
    (c >= "a" && c <= "z") || 
    (c >= "A" && c <= "Z") ||
    (c == "_")
  end

  def is_quote(c) do
    c == "\""
  end

  def is_num(c) do
    is_digit(c) || (c == ".")
  end

  def single_char_op(_chars = [char | rest], tokens) do
    token = 
      case char do
        "(" -> Token.new(type: LEFT_PAREN, lexeme: char)
        ")" -> Token.new(type: RIGHT_PAREN, lexeme: char)
        "{" -> Token.new(type: LEFT_BRACE, lexeme: char)
        "}" -> Token.new(type: RIGHT_BRACE, lexeme: char)
        "," -> Token.new(type: COMMA, lexeme: char)
        "." -> Token.new(type: DOT, lexeme: char)
        "-" -> Token.new(type: MINUS, lexeme: char)
        "+" -> Token.new(type: PLUS, lexeme: char)
        ";" -> Token.new(type: SEMICOLON, lexeme: char)
        "*" -> Token.new(type: STAR, lexeme: char)
         _  -> error("Unexpected char " <> char)
      end

    tokenize(rest, [token | tokens]) # remember to do a reverse in the end
  end

  def identifier_op(chars, tokens) do
    {identifier, rest} = Enum.split_while(chars, &is_alpha/1)
    identifier = Enum.join(identifier) 
    
    token = Token.new(type: IDENTIFIER, lexeme: identifier)
    tokenize(rest, [token | tokens])
  end

  def string_op(_chars = [h | t], tokens) do
    # h is "
    # t is the rest of the string
    # Let's consume the string until we found another quotation mark
    {identifier, rest} = Enum.split_while(t, fn(x) -> !is_quote(x) end)
    identifier = Enum.join(identifier)
    token = Token.new(type: STRING, lexeme: h <> identifier <> h)
    tokenize(tl(rest), [token | tokens])
  end

  def can_be_double_char(c) do
    (c == "=") || (c == "!") || (c == "<") || (c == ">")
  end

  def double_char_op(chars = [h | t], tokens) do
    token = 
      case h do
        "=" when hd(t) == "=" -> 
          Token.new(type: EQUAL_EQUAL, lexeme: "==")
        "=" -> 
          Token.new(type: EQUAL, lexeme: "=")

        "!" when hd(t) == "=" -> 
          Token.new(type: BANG_EQUAL, lexeme: "!=")
        "!" ->
          Token.new(type: BANG, lexeme: "!")

        "<" when hd(t) == "=" -> 
          Token.new(type: LESS_EQUAL, lexeme: "<=")
        "<" ->
          Token.new(type: LESS, lexeme: "<")

        ">" when hd(t) == "=" ->
          Token.new(type: GREATER_EQUAL, lexeme: ">=")
        ">" ->
          Token.new(type: GREATER, lexeme: ">")
      end

    type = token.type
    case type do
      type when type in [EQUAL, BANG, LESS, GREATER] ->
        tokenize(t, [token | tokens])
      _ ->
        tokenize(tl(t), [token | tokens])
    end
  end


  def number_op(chars, tokens) do
    {number, rest} = Enum.split_while(chars, &is_num/1)
    number = Enum.join(number)

    token = Token.new(type: NUMBER, lexeme: number)
    tokenize(rest, [token | tokens])
  end

  def is_whitespace(c) do
    (c == "") || (c == " ") || 
    (c == "\n") || (c == "\t") || (c == "\r")
  end

  def tokenize (content) do
    chars = String.split(content, "", trim: true)
    tokenize(chars, [])
  end

  def tokenize(chars = [char | rest], tokens) do
    cond do
      is_whitespace(char) -> tokenize(rest, tokens)
      is_alpha(char) -> identifier_op(chars, tokens)
      is_quote(char) -> string_op(chars, tokens)
      is_digit(char) -> number_op(chars, tokens)
      can_be_double_char(char) -> double_char_op(chars, tokens)
      true -> single_char_op(chars, tokens)
    end
  end

  def tokenize([], tokens) do
    Enum.reverse(tokens)
  end

end


