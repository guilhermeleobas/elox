defmodule ParserError do
  defexception message: "Parser Error"
end

defmodule Parser do

  @enforce_keys [:curr, :peek, :rest, :errors]
  defstruct [:curr, :peek, :rest, :errors]

  defp new(tokens) do
    [curr | [peek | rest]] = tokens
    %Parser{curr: curr, peek: peek, rest: rest, errors: []}
  end

  defp next_token(%Parser{} = p) do
    [h | t] = p.rest
    %{p | curr: p.peek, peek: h, rest: t}
  end

  defp add_error(%Parser{} = p, message) do
    %{p | errors: [message | p.errors]}
  end

  def parse(tokens) do
    new(tokens)
    |> parse_expression([])
  end

  def parse_expression(p, statements) do
    # expression → equality ;

    parse_equality(p, statements)
  end

  def parse_equality(p, statements) do
    # equality → comparison ( ( "!=" | "==" ) comparison )* ;

    {p, statements} = parse_comparison(p, statements)
    case p.curr.type do
      value when value in [BANG_EQUAL, EQUALS_EQUAL] ->
        parse_comparison(next_token(p), [p.curr | statements])
      _ -> 
        msg = "Expected != or == but got #{p.curr}"
        {add_error(p, msg), statements}
    end

  end

  def parse_comparison(p, statements) do
    # comparison → addition ( ( ">" | ">=" | "<" | "<=" ) addition )* ;

    {p, statements} = parse_addition(p, statements)
    case p.curr.type do
      value when value in [GREATER, GREATER_EQUAL, LESS, LESS_EQUAL] ->
        parse_addition(next_token(p), [p.curr | statements])
      _ -> 
        msg = "Expected >, >=, <, <= but got #{p.curr}"
        {add_error(p, msg), statements}
    end
  end

  def parse_addition(p, statements) do
    # addition → multiplication ( ( "-" | "+" ) multiplication )* ;

    {p, statements} = parse_multiplication(p, statements)
    case p.curr.type do
      value when value in [MINUS, PLUS] ->
        parse_multiplication(next_token(p), [p.curr | statements])
      _ -> 
        msg = "Expected - or + but got #{p.curr}"
        {add_error(p, msg), statements}
    end
  end

  def parse_multiplication(p, statements) do
    # multiplication → unary ( ( "/" | "*" ) unary )* ;
    
    {p, statements} = parse_unary(p, statements)
    case p.curr.type do
      value when value in [STAR, SLASH] ->
        parse_unary(next_token(p), [p.curr | statements])
      _ -> 
        msg = "Expected / or * but got #{p.curr}"
        {add_error(p, msg), statements}
    end
  end

  def parse_unary(p, statements) do
    # unary → ( "!" | "-" ) unary
    #         | primary ;

    case p.curr.type do
      value when value in [BANG, MINUS] ->
        parse_unary(next_token(p), [p.curr | statements])
      _ -> 
        parse_primary(p, statements)
    end
  end

  def parse_primary(p, statements) do
    # primary → NUMBER | STRING | "false" | "true" | "nil"
    #         | "(" expression ")" ;

    case p.curr.type do
      value when value in [NUMBER, STRING, FALSE, TRUE, NIL] -> 
        {next_token(p), [p.curr | statements]}
      _ -> 
        msg = "Expected a number, string, false, true, nil, (expr) but got #{p.curr}"
        {add_error(p, msg), statements}
    end
  end


end