defmodule LexerError do
  defexception message: "Lexer error"
end

defmodule Lox.Lexer do
  alias Lox.Token

  def error(message) do
    raise message
  end

  def is_digit(c) do
    c >= "0" && c <= "9"
  end

  def is_alpha(c) do
    (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || c == "_"
  end

  def is_quote(c) do
    c == "\""
  end

  def is_slash(c) do
    c == "/"
  end

  def slash_or_comment(chars = [h | t], tokens, lineno) do
    # we already know that h is a slash
    case hd(t) do
      "/" ->
        {comment, rest} = Enum.split_while(chars, fn x -> !is_endline(x) end)

        cond do
          rest == [] ->
            tokenize([], tokens, lineno)

          hd(rest) == "\n" ->
            tokenize(tl(rest), tokens, lineno+1)

          true ->
            tokenize(rest, tokens, lineno)
        end

      _ ->
        token = Token.new(type: :SLASH, lexeme: h, line: lineno)
        tokenize(t, [token | tokens], lineno)
    end
  end

  def single_char_op(_chars = [char | rest], tokens, lineno) do
    token =
      case char do
        "(" -> Token.new(type: :LEFT_PAREN, lexeme: char, line: lineno)
        ")" -> Token.new(type: :RIGHT_PAREN, lexeme: char, line: lineno)
        "{" -> Token.new(type: :LEFT_BRACE, lexeme: char, line: lineno)
        "}" -> Token.new(type: :RIGHT_BRACE, lexeme: char, line: lineno)
        "," -> Token.new(type: :COMMA, lexeme: char, line: lineno)
        "." -> Token.new(type: :DOT, lexeme: char, line: lineno)
        "-" -> Token.new(type: :MINUS, lexeme: char, line: lineno)
        "+" -> Token.new(type: :PLUS, lexeme: char, line: lineno)
        ";" -> Token.new(type: :SEMICOLON, lexeme: char, line: lineno)
        "*" -> Token.new(type: :STAR, lexeme: char, line: lineno)
        _ -> raise LexerError, message: "Lexer Error: Unexpected char #{char}"
      end

    # remember to do a reverse in the end
    tokenize(rest, [token | tokens], lineno)
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
      "while" => :WHILE
    }

    # tries to match the lexeme against the reserved
    # ones and fallback to IDENTIFIER if not found.
    Map.get(types, lexeme, :IDENTIFIER)
  end

  def identifier_op(chars, tokens, lineno) do
    {identifier, rest} = Enum.split_while(chars, &is_alpha/1)
    identifier = Enum.join(identifier)

    type = get_identifier_type(identifier)
    token = Token.new(type: type, lexeme: identifier, line: lineno)
    tokenize(rest, [token | tokens], lineno)
  end

  def string_op(_chars = [h | t], tokens, lineno) do
    # h is "
    # t is the rest of the string
    # Let's consume the string until we find another quotation mark
    {identifier, rest} = Enum.split_while(t, fn x -> !is_quote(x) end)
    identifier = Enum.join(identifier)
    token = Token.new(type: :STRING, lexeme: "\"#{identifier}\"", line: lineno)
    tokenize(tl(rest), [token | tokens], lineno)
  end

  def can_be_double_char(c) do
    c == "=" || c == "!" || c == "<" || c == ">"
  end

  def double_char_op(_chars = [h | t], tokens, lineno) do
    token =
      case h do
        "=" when hd(t) == "=" ->
          Token.new(type: :EQUAL_EQUAL, lexeme: "==", line: lineno)

        "=" ->
          Token.new(type: :EQUAL, lexeme: "=", line: lineno)

        "!" when hd(t) == "=" ->
          Token.new(type: :BANG_EQUAL, lexeme: "!=", line: lineno)

        "!" ->
          Token.new(type: :BANG, lexeme: "!", line: lineno)

        "<" when hd(t) == "=" ->
          Token.new(type: :LESS_EQUAL, lexeme: "<=", line: lineno)

        "<" ->
          Token.new(type: :LESS, lexeme: "<", line: lineno)

        ">" when hd(t) == "=" ->
          Token.new(type: :GREATER_EQUAL, lexeme: ">=", line: lineno)

        ">" ->
          Token.new(type: :GREATER, lexeme: ">", line: lineno)
      end

    type = token.type

    case type do
      type when type in [:EQUAL, :BANG, :LESS, :GREATER] ->
        tokenize(t, [token | tokens], lineno)

      _ ->
        tokenize(tl(t), [token | tokens], lineno)
    end
  end

  def number_op(chars, tokens, lineno) do
    {number_arr, rest} = Enum.split_while(chars, &is_digit/1)

    # Check if we have a dot on hd(rest)
    # Here we use List.first instead of hd because rest can be an
    # empty list and if it is, we match on the last condition ( _ -> ... ).
    {number_arr, rest} =
      case List.first(rest) do
        "." ->
          {frac_arr, rest2} = Enum.split_while(tl(rest), &is_digit/1)

          case frac_arr do
            [] ->
              number = Enum.join(number_arr) <> "."
              raise LexerError, message: "Error creating token for number #{number} on line #{lineno}"

            _ ->
              {number_arr ++ ["."] ++ frac_arr, rest2}
          end

        _ ->
          {number_arr ++ [".0"], rest}
      end

    integer = Enum.join(number_arr)
    token = Token.new(type: :NUMBER, lexeme: integer, line: lineno)

    tokenize(rest, [token | tokens], lineno)
  end

  def is_endline(c) do
    c == "\n"
  end

  def is_whitespace(c) do
    c == "" || c == " " || c == "\t" || c == "\r"
  end

  def tokenize(content) do
    chars = String.split(content, "", trim: true)
    tokenize(chars, [], 1)
  end

  def tokenize(chars = [char | rest], tokens, lineno) do
    cond do
      is_slash(char) -> 
        slash_or_comment(chars, tokens, lineno)
      is_whitespace(char) ->
        tokenize(rest, tokens, lineno)
      is_endline(char) -> 
        tokenize(rest, tokens, lineno+1)
      is_alpha(char) -> 
        identifier_op(chars, tokens, lineno)
      is_quote(char) -> 
        string_op(chars, tokens, lineno)
      is_digit(char) -> 
        number_op(chars, tokens, lineno)
      can_be_double_char(char) -> 
        double_char_op(chars, tokens, lineno)
      true -> 
        single_char_op(chars, tokens, lineno)
    end
  end

  def tokenize([], tokens, lineno) do
    Enum.reverse([Token.new(type: :EOF, lexeme: "", line: lineno) | tokens])
  end
end
