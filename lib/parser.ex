defmodule ParserError do
  defexception message: "Parser Error"
end

defmodule Parser do

  alias Lox.Ast.{
    Literal,
    Unary,
    Binary,
    Grouping,
    Stmt,
    PrintStmt,
    VarDecl,
    Assign,
  }

  @enforce_keys [:curr, :peek, :rest, :errors]
  defstruct [:curr, :peek, :rest, :errors]

  def from_tokens(tokens) do
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

  # `expect` checks if the current token is the expected one
  # if yes, advance to the next token. Otherwise, throws an error
  defp expect(%Parser{} = p, token_type) do
    if p.curr.type == token_type do
      next_token(p)
    else
      raise ParserError, message: "Expected #{token_type} but got:\n curr: #{p.curr} \n peek: #{p.peek}"
    end
  end

  # `match` returns `true` when the current token is the expected one
  # `false` otherwise.
  defp match(%Parser{curr: curr} = _p, token_type) do
    if curr.type == token_type do
      true
    else
      false
    end
  end

  defp consume(%Parser{curr: curr} = p, token_type) do
    if curr.type == token_type do
      {next_token(p), curr}
    else
      :error
    end
  end

  def parse(tokens) do
    from_tokens(tokens)
    |> parse_program([])
  end

  def parse_program(%Parser{curr: %Token{type: :EOF}} = _p, stmts) do
    stmts
  end

  def parse_program(p, stmts) do
    # program → declaration* EOF ;

    {p, stmt} = parse_declaration(p)

    parse_program(p, [stmt | stmts])
  end

  def parse_declaration(p) do
    # declaration → varDecl
    #             | statement ;

    cond do
      match(p, :VAR) -> parse_var_decl(p)
      true -> parse_statement(p)  
    end
  end

  def parse_var_decl(p) do
    # varDecl → "var" IDENTIFIER ( "=" expression )? ";" ;

    p = expect(p, :VAR)
    {p, idtn} = {expect(p, :IDENTIFIER), p.curr}

    {p, expr} = 
    if match(p, :EQUAL) do
      parse_expression(next_token(p))
    else
      {p, nil}
    end

    {expect(p, :SEMICOLON), %VarDecl{name: idtn, expr: expr}}
  end

  def parse_statement(p) do
    # statement → exprStmt
    #           | printStmt ;

    cond do
      match(p, :PRINT) -> parse_print_statement(p)
      true -> parse_expr_statement(p)
    end

  end

  def parse_expr_statement(p) do
    # exprStmt  → expression ";" ;

    {p, expr} = parse_expression(p);
    {expect(p, :SEMICOLON), %Stmt{expr: expr}}
  end

  def parse_print_statement(p) do
    # printStmt → "print" expression ";" ;

    p = expect(p, :PRINT)
    {p, expr} = parse_expression(p)
    {expect(p, :SEMICOLON), %PrintStmt{expr: expr}}
  end

  def parse_expression(p) do
    # expression → assignment ;
    parse_assignment(p)
  end

  def parse_assignment(p) do
    # assignment → IDENTIFIER "=" assignment
    #            | equality ;

    {p, expr} = parse_equality(p)

    with {p, _} <- consume(p, :EQUAL) do
      {p, value} = parse_assignment(p)
      {p, %Assign{name: expr.token, value: value}}
    else
      :error -> {p, expr}
    end

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
        {p, %Unary{token: op_token, operator: op, right: right}}
      _ -> 
        parse_primary(p) # returns {p, literal}. Just propagate
    end
  end

  def parse_primary(p) do
    # primary → NUMBER | STRING | "false" | "true" | "nil" | "this" | IDENTIFIER
    #         | "(" expression ")" ;

    case p.curr.type do
      type when type in [:NUMBER, :STRING, :FALSE, :TRUE, :NIL, :THIS, :IDENTIFIER] -> 
        literal = %Literal{token: p.curr}
        {next_token(p), literal}

      :LEFT_PAREN -> 
        {p, expr} = parse_expression(next_token(p))
        
        {expect(p, :RIGHT_PAREN), %Grouping{expr: expr}}

      _ -> 
        msg = "Expected a number, string, false, true, nil, (expr) but got #{p.curr}"
        raise ParserError, message: msg
    end
  end


end