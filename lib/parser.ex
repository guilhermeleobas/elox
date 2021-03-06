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
    Logical,
    While,
    Call,
    Function,
    Return
  }

  alias Lox.Token

  @enforce_keys [:curr, :peek, :rest]
  defstruct [:curr, :peek, :rest]

  def from_tokens(tokens) do
    [curr | [peek | rest]] = tokens
    %Lox.Parser{curr: curr, peek: peek, rest: rest}
  end

  defp next_token(%Lox.Parser{rest: []} = p) do
    %{p | curr: p.peek, peek: nil}
  end

  defp next_token(%Lox.Parser{} = p) do
    [h | t] = p.rest
    %{p | curr: p.peek, peek: h, rest: t}
  end

  # `expect` checks if the current token is the expected one
  # if yes, advance to the next token. Otherwise, throws an error
  defp expect(%Lox.Parser{} = p, expected_type, msg \\ "") do
    if p.curr.type == expected_type do
      next_token(p)
    else
      message = 
        if msg == "" do
          "Expected #{expected_type} but got #{p.curr} on line #{p.curr.line}"
        else
          msg
        end
      raise ParserError, message: message
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

  ###############################################################################################

  def parse(tokens) do
    from_tokens(tokens)
    |> parse_program([])
  end

  def parse_program(%Lox.Parser{curr: %Token{type: :EOF}} = _p, stmts) do
    stmts |> Enum.reverse()
  end

  def parse_program(p, stmts) do
    # program → declaration* EOF ;

    {p, stmt} = parse_declaration(p)

    parse_program(p, [stmt | stmts])
  end

  ###############################################################################################

  def parse_declaration(p) do
    # declaration → varDecl
    #             | funDecl
    #             | statement ;

    cond do
      match(p, :VAR) -> parse_var_decl(p)
      match(p, :FUN) -> parse_function_decl(p)
      true -> parse_statement(p)
    end
  end

  ###############################################################################################

  def parse_return_stmt(p) do
    # returnStmt → "return" expression? ";" ;
    {p, ret_keyword} = consume(p, :RETURN)
    
    {p, expr} = 
      if match(p, :SEMICOLON) do
        {expect(p, :SEMICOLON), %Literal{token: Token.new(type: :NIL, lexeme: "nil", line: ret_keyword.line)}}
      else
        {p, expr} = parse_expression(p)
        {expect(p, :SEMICOLON), expr}
      end
    {p, %Return{keyword: ret_keyword, expr: expr}}
  end

  def parse_func_decl_arguments(p) do
    # parameters → IDENTIFIER ( "," IDENTIFIER )* ;
    cond do
      match(p, :COMMA) ->
        parse_func_decl_arguments(next_token(p))

      match(p, :RIGHT_PAREN) ->
        {p, []}

      match(p, :IDENTIFIER) ->
        {p, idtn} = consume(p, :IDENTIFIER)
        {p, rest} = parse_func_decl_arguments(p)
        {p, [idtn | rest]}

      true ->
        expect(p, nil, "Expected :IDENTIFIER/:COMMA/:RIGHT_PAREN but got #{p.curr.type} on line #{p.curr.line}")
    end
  end

  def parse_function_decl(p) do
    # funDecl  → "fun" function ;
    # function → IDENTIFIER "(" parameters? ")" block ;

    p = expect(p, :FUN)
    {p, name} = {expect(p, :IDENTIFIER), p.curr}
    p = expect(p, :LEFT_PAREN)
    {p, args} = parse_func_decl_arguments(p)
    p = expect(p, :RIGHT_PAREN)
    {p, body} = parse_block(p)

    if length(args) > 8 do
      raise ParserError,
        message: "Function '#{name}' declared with more than 8 arguments"
    end

    {p, %Function{name: name, args: args, body: body}}
  end

  ###############################################################################################

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

  ###############################################################################################

  def parse_statement(p) do
    # statement → exprStmt
    #           | forStmt
    #           | ifStmt
    #           | printStmt 
    #           | returnStmt
    #           | whileStmt
    #           | block ;

    cond do
      match(p, :PRINT) ->
        parse_print_statement(p)

      match(p, :FOR) ->
        parse_for_statement(p)

      match(p, :RETURN) ->
        parse_return_stmt(p)

      match(p, :LEFT_BRACE) ->
        parse_block(p)

      match(p, :IF) ->
        parse_if_stmt(p)

      match(p, :WHILE) ->
        parse_while_stmt(p)

      true ->
        parse_expr_statement(p)
    end
  end

  ###############################################################################################

  defp append_or_create_block(body, nil), do: body

  defp append_or_create_block(%Block{stmt_list: stmts} = _body, inc),
    do: %Block{stmt_list: [stmts, inc] |> List.flatten()}

  defp append_or_create_block(body, inc), do: %Block{stmt_list: [body, inc]}

  def parse_for_statement(p) do
    # forStmt   → "for" "(" ( varDecl | exprStmt | ";" )
    #                    expression? ";"
    #                    expression? ")" statement ; 

    with p <- expect(p, :FOR),
         p <- expect(p, :LEFT_PAREN) do
      {p, initializer} =
        cond do
          match(p, :SEMICOLON) -> {expect(p, :SEMICOLON), nil}
          match(p, :VAR) -> parse_var_decl(p)
          true -> parse_expr_statement(p)
        end

      {p, cond_expr} =
        cond do
          # if the condition is nil, we replace it by a always true expression
          match(p, :SEMICOLON) -> 
            {p, %Literal{token: Token.new(type: :TRUE, lexeme: "true")}}
          true -> 
            parse_expression(p)
        end

      p = expect(p, :SEMICOLON)

      {p, increment} =
        if !match(p, :RIGHT_PAREN) do
          parse_expression(p)
        else
          {p, nil}
        end

      p = expect(p, :RIGHT_PAREN)

      #
      # initializer
      # while (cond)
      #   body
      #   increment
      # 
      # We create a block for the body + increment
      {p, body} = parse_statement(p)
      body = append_or_create_block(body, increment)

      while = %While{cond_expr: cond_expr, stmt_body: body}

      if initializer == nil do
        {p, %Block{stmt_list: [while]}}
      else
        {p, %Block{stmt_list: [initializer, while]}}
      end
    end
  end

  ###############################################################################################

  def parse_while_stmt(p) do
    # whileStmt → "while" "(" expression ")" statement ;
    with p <- expect(p, :WHILE),
         p <- expect(p, :LEFT_PAREN) do
      {p, cond_expr} = parse_expression(p)
      {p, stmt_body} = parse_statement(expect(p, :RIGHT_PAREN))

      {p, %While{cond_expr: cond_expr, stmt_body: stmt_body}}
    end
  end

  ###############################################################################################

  def parse_if_stmt(p) do
    # ifStmt    → "if" "(" expression ")" statement ( "else" statement )? ;

    {p, cond_expr, then_stmt, else_stmt} =
      with p <- expect(p, :IF),
           p <- expect(p, :LEFT_PAREN) do
        {p, cond_expr} = parse_expression(p)

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

  ###############################################################################################

  def parse_block(p, stmt_list) do
    if match(p, :RIGHT_BRACE) do
      {p, stmt_list |> Enum.reverse()}
    else
      {p, decl} = parse_declaration(p)
      parse_block(p, [decl | stmt_list])
    end
  end

  def parse_block(p) do
    # block → "{" declaration* "}" ;

    p = expect(p, :LEFT_BRACE)
    {p, stmt_list} = parse_block(p, [])
    {expect(p, :RIGHT_BRACE), %Block{stmt_list: stmt_list}}
  end

  ###############################################################################################

  def parse_expr_statement(p) do
    # exprStmt  → expression ";" ;

    {p, expr} = parse_expression(p)
    {expect(p, :SEMICOLON), %Stmt{expr: expr}}
  end

  ###############################################################################################

  def parse_print_statement(p) do
    # printStmt → "print" expression ";" ;

    p = expect(p, :PRINT)
    {p, expr} = parse_expression(p)
    {expect(p, :SEMICOLON), %PrintStmt{expr: expr}}
  end

  ###############################################################################################

  def parse_expression(p) do
    # expression → assignment ;
    parse_assignment(p)
  end

  ###############################################################################################

  def parse_assignment(p) do
    # assignment → identifier "=" assignment
    #            | logic
    #            | equality ;

    {p, left} = parse_equality(p)

    cond do
      match(p, :EQUAL) ->
        {p, value} = parse_assignment(next_token(p))
        {p, %Assign{name: left.token, expr: value}}

      match(p, :AND) || match(p, :OR) ->
        parse_logic(p, left)

      true ->
        {p, left}
    end
  end

  ###############################################################################################

  def parse_logic_exprs(p, left) do
    if match(p, :OR) || match(p, :AND) do
      op_token = p.curr
      op = op_token.type
      {p, right} = parse_equality(next_token(p))
      {p, bin} = {p, %Logical{left: left, operator: op, right: right}}
      parse_logic_exprs(p, bin)
    else
      {p, left}
    end
  end

  def parse_logic(p, left) do
    parse_logic_exprs(p, left)
  end

  ###############################################################################################
  
  def parse_equality_exprs(p, left) do
    if match(p, :BANG_EQUAL) || match(p, :EQUAL_EQUAL) do
      op_token = p.curr
      op = op_token.type
      {p, right} = parse_comparison(next_token(p))
      {p, bin} = {p, %Binary{token: op_token, left: left, operator: op, right: right}}
      parse_addition_exprs(p, bin)
    else
      {p, left}
    end
  end

  def parse_equality(p) do
    # equality → comparison ( ( "!=" | "==" ) comparison )* ;
    {p, left} = parse_comparison(p)
    parse_equality_exprs(p, left)
  end

  ###############################################################################################

  def parse_comparison_exprs(p, left) do
    if match(p, :GREATER) || match(p, :GREATER_EQUAL) || match(p, :LESS) || match(p, :LESS_EQUAL) do
      op_token = p.curr
      op = op_token.type
      {p, right} = parse_addition(next_token(p))
      {p, bin} = {p, %Binary{token: op_token, left: left, operator: op, right: right}}
      parse_comparison_exprs(p, bin)
    else
      {p, left}
    end
  end
  
  def parse_comparison(p) do
    # comparison → addition ( ( ">" | ">=" | "<" | "<=" ) addition )* ;

    {p, left} = parse_addition(p)
    parse_comparison_exprs(p, left)
  end

  ###############################################################################################

  def parse_addition_exprs(p, left) do
    if match(p, :MINUS) || match(p, :PLUS) do
      op_token = p.curr
      op = op_token.type
      {p, right} = parse_multiplication(next_token(p))
      {p, bin} = {p, %Binary{token: op_token, left: left, operator: op, right: right}}
      parse_addition_exprs(p, bin)
    else
      {p, left}
    end
  end

  def parse_addition(p) do
    # addition → multiplication ( ( "-" | "+" ) multiplication )* ;
    {p, left} = parse_multiplication(p)
    parse_addition_exprs(p, left)
  end

  ###############################################################################################
  
  
  def parse_multiplication_exprs(p, left) do
    if match(p, :STAR) || match(p, :SLASH) do
      op_token = p.curr
      op = op_token.type
      {p, right} = parse_unary(next_token(p))
      {p, bin} = {p, %Binary{token: op_token, left: left, operator: op, right: right}}
      parse_multiplication_exprs(p, bin)
    else
      {p, left}
    end
  end

  def parse_multiplication(p) do
    # multiplication → unary ( ( "/" | "*" ) unary )* ;
    {p, left} = parse_unary(p)
    parse_multiplication_exprs(p, left)
  end
  
  ###############################################################################################

  def parse_unary(p) do
    # unary → ( "!" | "-" ) unary
    #         | call ;

    op_token = p.curr

    case op_token.type do
      op when op in [:BANG, :MINUS] ->
        {p, right} = parse_unary(next_token(p))
        {p, %Unary{token: op_token, operator: op, right: right}}

      _ ->
        # returns {p, literal}. Just propagate
        parse_call(p)
    end
  end

  ###############################################################################################

  def parse_func_call_arguments(p) do
    # arguments → expression ( "," expression )* ;
    cond do
      match(p, :COMMA) ->
        parse_func_call_arguments(next_token(p))

      match(p, :RIGHT_PAREN) ->
        {next_token(p), []}

      true ->
        {p, arg} = parse_expression(p)
        {p, rest} = parse_func_call_arguments(p)
        {p, [arg | rest]}
    end
  end

  def parse_call(p, function_name, calls_args) do
    cond do
      # whenever we find a "(", we parse args until we find a ")"
      match(p, :LEFT_PAREN) ->
        {p, args} = parse_func_call_arguments(next_token(p))

        if length(args) > 8 do
          raise ParserError,
            message: "Function call to '#{function_name}' with more than 8 arguments"
        end

        parse_call(p, function_name, calls_args ++ [args])

      true ->
        {p, calls_args}
        # expect(p, nil, "Expected :SEMICOLON or :LEFT_PAREN but got #{p.curr.type} on line #{p.curr.line}")
    end
  end

  def parse_call(p) do
    # call  → primary ( "(" arguments? ")" )* ;
    
    {p, function_name} = parse_primary(p)
      
    if match(p, :LEFT_PAREN) do
      {p, call_args} = parse_call(p, function_name, [])

      # function_name is a literal that contains the actual token
      # for the name. We send to the call the token and not the 
      # literal

      call =
        Enum.reduce(call_args, function_name.token, fn args, acc ->
          %Call{callee: acc, args: args}
        end)
      
      {p, call}
    else
      {p, function_name}
    end
  end

  ###############################################################################################

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
        msg = "Expected a number, string, false, true, nil, (expr) but got #{p.curr.type} on line #{p.curr.line}"
        expect(p, nil, msg)
    end
  end
end
