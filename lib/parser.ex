defmodule ParserError do
  defexception message: "Parser Error"
end

defmodule Parser do

  alias Lox.Ast.{
    Literal,
    Unary,
    Binary,
    Grouping,
  }

  @enforce_keys [:curr, :peek, :rest, :errors]
  defstruct [:curr, :peek, :rest, :errors]

  defp new(tokens) do
    [curr | [peek | rest]] = tokens
    %Parser{curr: curr, peek: peek, rest: rest, errors: []}
  end

  defp next_token(%Parser{rest: []} = p) do
    %{p | curr: p.peek, peek: nil, errors: []}
  end

  defp next_token(%Parser{} = p) do
    [h | t] = p.rest
    %{p | curr: p.peek, peek: h, rest: t, errors: []}
  end

  defp add_error(%Parser{} = p, message) do
    %{p | errors: [message | p.errors]}
  end

  defp expect(%Parser{} = p, token_type) do
    if p.curr.type == token_type do
      next_token(p)
    else
      raise ParserError, message: "Expected #{token_type} but got:\n curr: #{p.curr} \n peek: #{p.peek}"
    end
  end

  def parse(tokens) do
    new(tokens)
    |> parse_program([])
  end

  def parse_program(%Parser{curr: %Token{type: :EOF}} = _p, stmts) do
    # IO.puts "its over now!"
    stmts
  end

  def parse_program(p, stmts) do
    {p, expr} = parse_expression(p)

    parse_program(p, [expr | stmts])
  end

  def parse_expression(p) do
    # expression → equality ;

    parse_equality(p)
  end

  def parse_equality(p) do
    # equality → comparison ( ( "!=" | "==" ) comparison )* ;

    {p, left} = parse_comparison(p)
    op_token = p.curr

    case op_token.type do
      op when op in [:BANG_EQUAL, :EQUAL_EQUAL] ->
        {p, right} = parse_comparison(next_token(p))

        {p, %Binary{token: op_token, left: left, operator: op, right: right}}
      _ -> 
        msg = "Expected != or == but got #{p.curr}"
        {add_error(p, msg), left}
    end

  end

  def parse_comparison(p) do
    # comparison → addition ( ( ">" | ">=" | "<" | "<=" ) addition )* ;

    {p, left} = parse_addition(p)
    op_token = p.curr

    case op_token.type do
      op when op in [:GREATER, :GREATER_EQUAL, :LESS, :LESS_EQUAL] ->
        {p, right} = parse_addition(next_token(p))

        {p, %Binary{token: op_token, left: left, operator: op, right: right}}
      _ -> 
        msg = "Expected >, >=, <, <= but got #{p.curr}"
        {add_error(p, msg), left}
    end
  end

  def parse_addition(p) do
    # addition → multiplication ( ( "-" | "+" ) multiplication )* ;

    {p, left} = parse_multiplication(p)
    op_token = p.curr

    case op_token.type do
      op when op in [:MINUS, :PLUS] ->
        {p, right} = parse_multiplication(next_token(p))

        {p, %Binary{token: op_token, left: left, operator: op, right: right}}
      _ -> 
        msg = "Expected - or + but got #{p.curr}"
        {add_error(p, msg), left}
    end
  end

  def parse_multiplication(p) do
    # multiplication → unary ( ( "/" | "*" ) unary )* ;
    
    {p, left} = parse_unary(p)
    op_token = p.curr

    case op_token.type do
      op when op in [:STAR, :SLASH] ->
        {p, right} = parse_unary(next_token(p))

        {p, %Binary{token: op_token, left: left, operator: op, right: right}}
      _ -> 
        msg = "Expected / or * but got #{p.curr}"
        {add_error(p, msg), left}
    end
  end

  def parse_unary(p) do
    # unary → ( "!" | "-" ) unary
    #         | primary ;

    op_token = p.curr
    case op_token.type do
      op when op in [:BANG, :MINUS] ->
        {p, right} = parse_unary(next_token(p))
        # IO.inspect(p.curr)
        {p, %Unary{token: op_token, operator: op, right: right}}
      _ -> 
        parse_primary(p) # returns {p, literal}. Just propagate
    end
  end

  def parse_primary(p) do
    # primary → NUMBER | STRING | "false" | "true" | "nil"
    #         | "(" expression ")" ;

    case p.curr.type do
      type when type in [:NUMBER, :STRING, :FALSE, :TRUE, :NIL] -> 
        literal = %Literal{token: p.curr, value: p.curr.lexeme}
        {next_token(p), literal}

      :LEFT_PAREN -> 
        # {p, expr} = parse_expression(next_token(p))
        {p, expr} = parse_expression(next_token(p))
        
        {expect(p, :RIGHT_PAREN), %Grouping{expr: expr}}

      _ -> 
        msg = "Expected a number, string, false, true, nil, (expr) but got #{p.curr}"
        raise ParserError, message: msg
    end
  end


end