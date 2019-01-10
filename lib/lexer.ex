defmodule LexerError do
  defexception message: "Lexer error"
end

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

  def is_slash(c) do
    c == "/"
  end

  def slash_or_comment(chars = [h | t], tokens) do
    # we already know that h is a slash
    case hd(t) do
      "/" ->
        {comment, rest} = Enum.split_while(chars, fn(x) -> !is_endline(x) end)
        cond do
          rest == [] -> 
            tokenize([], tokens)
          hd(rest) == "\n" -> 
            tokenize(tl(rest), tokens)
          true -> 
            tokenize(rest, tokens)
        end
      _ ->
        token = Token.new(type: :SLASH, lexeme: h)
        tokenize(t, [token | tokens])
    end
  end

  def single_char_op(_chars = [char | rest], tokens) do
    token = 
      case char do
        "(" -> Token.new(type: :LEFT_PAREN, lexeme: char)
        ")" -> Token.new(type: :RIGHT_PAREN, lexeme: char)
        "{" -> Token.new(type: :LEFT_BRACE, lexeme: char)
        "}" -> Token.new(type: :RIGHT_BRACE, lexeme: char)
        "," -> Token.new(type: :COMMA, lexeme: char)
        "." -> Token.new(type: :DOT, lexeme: char)
        "-" -> Token.new(type: :MINUS, lexeme: char)
        "+" -> Token.new(type: :PLUS, lexeme: char)
        ";" -> Token.new(type: :SEMICOLON, lexeme: char)
        "*" -> Token.new(type: :STAR, lexeme: char)
         _  -> raise LexerError, message: "Lexer Error: Unexpected char #{char}"
      end

    tokenize(rest, [token | tokens]) # remember to do a reverse in the end
  end

  def get_identifier_type(lexeme) do
    types = %{
      "and" => :AND,
      "class" => :CLASS,
      "else" => :ELSE,
      "false" => :FALSE,
      "fun" => :FUN,
      "for" => :FOR,
      "if" => :IF,
      "nil" => :NIL,
      "or" => :OR,
      "print" => :PRINT,
      "return" => :RETURN,
      "super" => :SUPER,
      "this" => :THIS,
      "true" => :TRUE,
      "var" => :VAR,
      "while" => :WHILE,
    }

    # tries to match the lexeme against the reserved
    # ones and fallback to IDENTIFIER if not found.
    Map.get(types, lexeme, :IDENTIFIER)
  end

  def identifier_op(chars, tokens) do
    {identifier, rest} = Enum.split_while(chars, &is_alpha/1)
    identifier = Enum.join(identifier) 

    type = get_identifier_type(identifier)
    token = Token.new(type: type, lexeme: identifier)
    tokenize(rest, [token | tokens])
  end

  def string_op(_chars = [h | t], tokens) do
    # h is "
    # t is the rest of the string
    # Let's consume the string until we find another quotation mark
    {identifier, rest} = Enum.split_while(t, fn(x) -> !is_quote(x) end)
    identifier = Enum.join(identifier)
    token = Token.new(type: :STRING, lexeme: "\"#{identifier}\"")
    tokenize(tl(rest), [token | tokens])
  end

  def can_be_double_char(c) do
    (c == "=") || (c == "!") || (c == "<") || (c == ">")
  end

  def double_char_op(_chars = [h | t], tokens) do
    token = 
      case h do
        "=" when hd(t) == "=" -> 
          Token.new(type: :EQUAL_EQUAL, lexeme: "==")
        "=" -> 
          Token.new(type: :EQUAL, lexeme: "=")

        "!" when hd(t) == "=" -> 
          Token.new(type: :BANG_EQUAL, lexeme: "!=")
        "!" ->
          Token.new(type: :BANG, lexeme: "!")

        "<" when hd(t) == "=" -> 
          Token.new(type: :LESS_EQUAL, lexeme: "<=")
        "<" ->
          Token.new(type: :LESS, lexeme: "<")

        ">" when hd(t) == "=" ->
          Token.new(type: :GREATER_EQUAL, lexeme: ">=")
        ">" ->
          Token.new(type: :GREATER, lexeme: ">")
      end

    type = token.type
    case type do
      type when type in [:EQUAL, :BANG, :LESS, :GREATER] ->
        tokenize(t, [token | tokens])
      _ ->
        tokenize(tl(t), [token | tokens])
    end
  end

  def consume_digits(chars) do
    {number_arr, rest} = Enum.split_while(chars, &is_digit/1)

  end


  def number_op(chars, tokens) do
    {number_arr, rest} = Enum.split_while(chars, &is_digit/1)

    # Check if we have a dot on hd(rest)
    {number_arr, rest} = 
      # Here we use List.first instead of hd because rest can be an
      # empty list and if it is, we match on the last condition ( _ -> ... ).
      case List.first(rest) do
        "." -> 
          {frac_arr, rest2} = Enum.split_while(tl(rest), &is_digit/1)
          case frac_arr do
            [] -> 
              number = Enum.join(number_arr) <> "."
              raise LexerError, message: "Error creating token for number #{number}"
            _ -> {number_arr ++ ["."] ++ frac_arr, rest2}
          end
        _ -> 
          {number_arr, rest}
      end

    integer = Enum.join(number_arr)
    token = Token.new(type: :NUMBER, lexeme: integer)

    tokenize(rest, [token | tokens])
  end

  def is_endline(c) do
    c == "\n"
  end

  def is_whitespace(c) do
    (c == "") || (c == " ") || 
    (c == "\t") || (c == "\r")
  end

  def tokenize(content) do
    chars = String.split(content, "", trim: true)
    tokenize(chars, [])
  end

  def tokenize(chars = [char | rest], tokens) do
    cond do
      is_slash(char) -> slash_or_comment(chars, tokens)
      is_whitespace(char) || is_endline(char) -> tokenize(rest, tokens)
      is_alpha(char) -> identifier_op(chars, tokens)
      is_quote(char) -> string_op(chars, tokens)
      is_digit(char) -> number_op(chars, tokens)
      can_be_double_char(char) -> double_char_op(chars, tokens)
      true -> single_char_op(chars, tokens)
    end
  end

  def tokenize([], tokens) do
    Enum.reverse([Token.new(type: :EOF, lexeme: "") | tokens])
  end

end


