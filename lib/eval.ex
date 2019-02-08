defmodule EvalError do
  defexception message: "Parser Error"
end

defmodule ReturnException do
  defexception [:message, :value]
end

defmodule Eval do
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
    Function,
    Call,
    Return
  }

  alias Lox.{
    Lexer,
    Parser,
    Environment
  }
  
  ###############################################################################################

  defp eval(%Environment{} = env, %Stmt{} = stmt) do
    eval(env, stmt.expr)
  end

  ###############################################################################################
  
  defp eval(%Environment{} = env, %Binary{} = expr) do
    {env, left} = eval(env, expr.left)
    {env, right} = eval(env, expr.right)

    result =
      case expr.operator do
        :STAR ->
          left * right

        :SLASH ->
          left / right

        :MINUS ->
          left - right

        :PLUS ->
          cond do
            is_number(left) && is_number(right) -> left + right
            is_binary(left) && is_binary(right) -> left <> right
            true -> raise EvalError, message: "Error while evaluating binary expr: #{expr}"
          end

        :GREATER ->
          left > right

        :GREATER_EQUAL ->
          left >= right

        :LESS ->
          left < right

        :LESS_EQUAL ->
          left <= right

        :EQUAL_EQUAL ->
          left == right

        :BANG_EQUAL ->
          left != right
      end

    {env, result}
  end
  
  ###############################################################################################

  defp eval(%Environment{} = env, %Unary{} = unary) do
    with {env, right} <- eval(env, unary.right) do
      result =
        case unary.operator do
          :MINUS -> -right
          :BANG -> !right
        end

      {env, result}
    end
  end

  ###############################################################################################
  
  defp eval(%Environment{} = env, %Grouping{} = grouping) do
    eval(env, grouping.expr)
  end
  
  ###############################################################################################

  defp eval(%Environment{} = env, %Literal{} = literal) do
    result =
      case literal.token.type do
        :NUMBER -> literal.token.lexeme |> Float.parse() |> elem(0)
        :STRING -> literal.token.lexeme
        :FALSE -> false
        :TRUE -> true
        :NIL -> nil
        :IDENTIFIER -> Environment.get(env, literal.token.lexeme)
      end

    {env, result}
  end

  ###############################################################################################
  
  defp eval(%Environment{} = env, %VarDecl{} = var) do
    lexeme = var.name.lexeme

    {env, value} =
      if var.expr != nil do
        eval(env, var.expr)
      else
        {env, nil}
      end

    env = Environment.put(env, lexeme, value)
    {env, nil}
  end
  
  ###############################################################################################

  defp eval(%Environment{} = env, %Assign{} = assign) do
    lexeme = assign.name.lexeme
    {env, value} = eval(env, assign.expr)

    with true <- Environment.contains(env, lexeme) do
      env = Environment.update(env, lexeme, value)
      {env, value}
    else
      _ -> raise EvalError, message: "Undefined variable #{lexeme}"
    end
  end
  
  ###############################################################################################

  defp eval(%Environment{} = env, %PrintStmt{} = print_stmt) do
    {env, result} = eval(env, print_stmt.expr)

    result
    |> IO.write()

    {env, nil}
  end
  
  ###############################################################################################

  defp eval(%Environment{} = env, %Logical{} = logical) do
    case logical.operator do
      :AND ->
        {env, value} = eval(env, logical.left)

        if is_truthy(value) != true do
          {env, value}
        else
          eval(env, logical.right)
        end

      :OR ->
        {env, value} = eval(env, logical.left)

        if is_truthy(value) == true do
          {env, value}
        else
          eval(env, logical.right)
        end
    end
  end
  
  ###############################################################################################

  defp eval(%Environment{} = env, %Block{} = block) do
    env =
      Enum.reduce(block.stmt_list, Environment.new(env), fn stmt, inner_env ->
        {inner_env, _} = eval(inner_env, stmt)
        inner_env
      end)

    {env.outer, nil}
  end
  
  ###############################################################################################

  defp eval(%Environment{} = env, %While{} = while) do
    {env, value} = eval(env, while.cond_expr)

    if is_truthy(value) do
      {env, _} = eval(env, while.stmt_body)
      eval(env, while)
    else
      {env, nil}
    end
  end
  
  ###############################################################################################

  defp eval(%Environment{} = env, %If{} = if_stmt) do
    {env, c} = eval(env, if_stmt.cond_expr)
    
    cond do
      c == true && if_stmt.then_stmt != nil ->
        eval(env, if_stmt.then_stmt)
      c == false && if_stmt.else_stmt != nil ->
        eval(env, if_stmt.else_stmt)
      true ->
        {env, nil}
    end
  end
  
  ###############################################################################################

  defp eval(%Environment{} = env, %Return{} = return) do
    {env, value} = eval(env, return.expr)
    throw({env, value})
  end
  
  ###############################################################################################
  

  defp eval(%Environment{} = env, %Function{} = function) do
    key = Function.get_name(function)
    env = Environment.put(env, key, function)
    {env, nil}
  end
  
  defp eval(%Environment{} = env, %Call{} = call) do
    callee = Call.get_name(call)
    fun = Environment.get(env, callee, opts: [type: "function"])
    check_arity(fun, call) # raises an exception
    fn_env = bind_args(env, fun, call)

    # The idea is that when Elox evals a Return Stmt, it
    # throws the return value and we catch it here
    return_value = 
      try do
        eval(fn_env, fun.body)
      catch
        {_, return_value} -> return_value # if we reach a return stmt
      else
        {_, return_value} -> return_value # if we don't reach a return stmt.
                                          # i.e. a function with empty body
      end
    
    {env, return_value}
  end
  
  defp check_arity(%Function{} = function, %Call{} = call) do
    fn_arity = Function.arity(function)
    call_arity = Call.arity(call)

    fun_name = Function.get_name(function)
    fn_line = Function.get_line(function)
    call_line = Call.get_line(call)

    if fn_arity != call_arity do
      raise EvalError, 
        message: "Function '#{fun_name}' was declared with '#{fn_arity}' parameters (line: #{fn_line}) 
        but called with '#{call_arity}' (line: #{call_line})"
    end
    
    true
  end

  defp bind_args(%Environment{} = outer, %Function{args: fn_args} = _function, %Call{args: call_args} = _call) do
    inner = Environment.new(outer)
    Enum.zip(fn_args, call_args)
    |> Enum.reduce(inner, fn {fn_arg, call_arg}, inner ->
      key = fn_arg.lexeme
      {_, value} = eval(outer, call_arg)
      Environment.put(inner, key, value)
    end)
  end

  ###############################################################################################
  
  defp is_truthy(value) do
    cond do
      is_nil(value) ->
        false

      is_boolean(value) ->
        value

      true ->
        true
    end
  end
  
  ###############################################################################################

  def eval_program(program) do
    env = Environment.new()

    {values, env} =
      Lexer.tokenize(program)
      |> Parser.parse()
      |> Enum.flat_map_reduce(env, fn stmt, env ->
        {env, value} = eval(env, stmt)
        {[value], env}
      end)

    {env, values}
  end
end
