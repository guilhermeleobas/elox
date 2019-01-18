defmodule EvalError do
  defexception message: "Parser Error"
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
  }

  alias Lox.{
    Lexer,
    Parser,
    Environment,
  }

  defp eval(%Environment{} = env, %Stmt{} = stmt) do
    eval(env, stmt.expr)
  end

  defp eval(%Environment{} = env, %Binary{} = expr) do
    {env, left}  = eval(env, expr.left)
    {env, right} = eval(env, expr.right)
      
    result =     
    case expr.operator do
      :STAR -> left * right
      :SLASH -> left / right
      :MINUS -> left - right
      :PLUS -> 
        cond do
          is_number(left) && is_number(right) -> left + right
          is_binary(left) && is_binary(right) -> left <> right
          true -> raise EvalError, message: "Error while evaluating binary expr: #{expr}"
        end
      :GREATER -> left > right
      :GREATER_EQUAL -> left >= right
      :LESS -> left < right
      :LESS_EQUAL -> left <= right
      :EQUAL_EQUAL -> left == right
      :BANG_EQUAL -> left != right
    end

    {env, result}

  end

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

  defp eval(%Environment{} = env, %Grouping{} = grouping) do
    eval(env, grouping.expr)
  end

  defp eval(%Environment{} = env, %Literal{} = literal) do
    result =
    case literal.token.type do
      :NUMBER -> literal.token.lexeme |> Float.parse |> elem(0)
      :STRING -> literal.token.lexeme
      :FALSE -> false
      :TRUE -> true
      :NIL -> nil
    end
    {env, result}
  end

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

  defp eval(%Environment{} = env, %Assign{} = assign) do

    lexeme = assign.name.lexeme
    {env, value} = eval(env, assign.expr)

    with true <- Environment.contains(env, lexeme) do
      env = Environment.put(env, lexeme, value)
      {env, nil}
    else
      _ -> raise EvalError, message: "Undefined variable #{lexeme}"
    end

  end

  defp eval(%Environment{} = env, %PrintStmt{} = print_stmt) do
    {env, result} = eval(env, print_stmt.expr)

    result
    |> IO.write

    {env, nil}
  end

  def eval_program(program) do
    env = Environment.new()

    {values, env} = 
    Lexer.tokenize(program)
    |> Parser.parse
    |> Enum.flat_map_reduce(env, fn stmt, env -> 
      {env, value} = eval(env, stmt)
      {[value], env} 
    end)

    {env, values}

  end


end