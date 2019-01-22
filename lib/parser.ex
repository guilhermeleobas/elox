defmodule ParserError do
  defexception message: "Parser Error"
end

defmodule Lox.Parser do

  alias Lox.Ast.{
    Literal,
    Unary,
    Binary,
    Grouping,
    Stmt,
    PrintStmt,
    VarDecl,
    Assign,
    Block,
    If,
  }

  alias Lox.Token

  @enforce_keys [:curr, :peek, :rest, :errors]
  defstruct [:curr, :peek, :rest, :errors]

  def from_tokens(tokens) do
    [curr | [peek | rest]] = tokens
    %Lox.Parser{curr: curr, peek: peek, rest: rest, errors: []}
  end

  defp next_token(%Lox.Parser{rest: []} = p) do
    %{p | curr: p.peek, peek: nil, errors: []}
  end

  defp next_token(%Lox.Parser{} = p) do
    [h | t] = p.rest
    %{p | curr: p.peek, peek: h, rest: t, errors: []}
  end

  defp add_error(%Lox.Parser{} = p, message) do
    %{p | errors: [message | p.errors]}
  end

  # `expect` checks if the current token is the expected one
  # if yes, advance to the next token. Otherwise, throws an error
  defp expect(%Lox.Parser{} = p, expected_type) do
    if p.curr.type == expected_type do
      next_token(p)
    else
      raise ParserError, message: "Expected #{expected_type} but got:\n curr: #{p.curr} \n peek: #{p.peek}"
    end
  end

  # `match` returns `true` when the current token is the expected one
  # `false` otherwise.
  defp match(%Lox.Parser{curr: curr} = _p, expected_type) do
    if curr.type == expected_type do
      true
    else
      false
    end
  end

  # `consume` consumes the current token if it's type is
  # equals to the expected one. Otherwise, just return `:error`
  defp consume(%Lox.Parser{curr: curr} = p, expected_type) do
    if curr.type == expected_type do
      {next_token(p), curr}
    else
      :error
    end
  end

  def parse(tokens) do
    from_tokens(tokens)
    |> parse_program([])
  end

  def parse_program(%Lox.Parser{curr: %Token{type: :EOF}} = _p, stmts) do
    stmts |> Enum.reverse
  end

  def parse_program(p, stmts) do
    # program → declaration* EOF ;

    {p, stmt} = parse_declaration(p)

    parse_program(p, [stmt | stmts])
  end

  def parse_declaration(p) do
    # declaration → varDecl
    #             | statement ;

    if match(p, :VAR) do
      parse_var_decl(p)
    else
      parse_statement(p)
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
    #           | ifStmt
    #           | printStmt ;
    #           | block ;

    cond do
      match(p, :PRINT) -> parse_print_statement(p)
      match(p, :LEFT_BRACE) -> parse_block(p)
      match(p, :IF) -> parse_if_stmt(p)
      true -> parse_expr_statement(p)
    end

  end

  def parse_block(p, stmt_list) do
    if p.curr.type == :RIGHT_BRACE do
      {p, stmt_list |> Enum.reverse}
    else
      {p, decl} = parse_declaration(p)
      parse_block(p, [decl | stmt_list])
    end
  end

  def parse_if_stmt(p) do
    # ifStmt    → "if" "(" expression ")" statement ( "else" statement )? ;

    {p, cond_expr, then_stmt, else_stmt} =
    with p <- expect(p, :IF),
         p <- expect(p, :LEFT_PAREN) do
      {p, cond_expr} = 
      parse_expression(p)

      {p, then_stmt} = parse_statement(expect(p, :RIGHT_PAREN))

      {p, else_stmt} =
      if match(p, :ELSE) do
        parse_statement(next_token(p))
      else
        {p, nil}
      end

      {p, cond_expr, then_stmt, else_stmt}
    end

    {p, %If{cond_expr: cond_expr, then_stmt: then_stmt, else_stmt: else_stmt}}

  end

  def parse_block(p) do
    # block → "{" declaration* "}" ;

    p = expect(p, :LEFT_BRACE)
    {p, stmt_list} = parse_block(p, [])
    {expect(p, :RIGHT_BRACE), %Block{stmt_list: stmt_list}}

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
      {p, %Assign{name: expr.token, expr: value}}
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