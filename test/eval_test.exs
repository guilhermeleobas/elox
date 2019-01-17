defmodule EvalTest do
  use ExUnit.Case

  alias Lox.Environment

  import ExUnit.CaptureIO
  
  doctest Eval

  test "Eval Literal" do
    values = [
      {"2;", 2.0},
      {"\"hello\";", "\"hello\""},
      {"nil;", nil},
      {"true;", true},
      {"false;", false}
    ]
    
    Enum.each(values, fn {input, expected} ->
      output = 
      Eval.eval_program(input)

      assert elem(output, 1) == expected, message: "Eval Literal"
    end)
  end

  test "Eval Unary/Binary/Grouping Expressions" do
    values = [
      {"2 + 3;", 5.0},
      {"(5 - (3 - 1)) + -1;", 2.0},
      {"!false;", true},
      {"!true;", false},
      {"2 > 3;", false},
      {"2 >= 3;", false},
      {"2 < 3;", true},
      {"2 < 3;", true},
      {"2 <= 3;", true},
      {"3 == 3;", true},
      {"2 == 3;", false},
      {"2 != 3;", true},
      {"nil == nil;", true},
      {"nil == true;", false},
      {"2 == nil;", false},
      {"\"Hello\" + \" World!\";", "\"Hello\"\" World!\""}
    ]
    
    Enum.each(values, fn {input, expected} ->
      output = Eval.eval_program(input)

      assert elem(output, 1) == expected
    end)
  end

  test "Eval StmtPrint" do
    values = [
      {"print (2 + 1);", "3.0"},
      {"print true;", "true"},
      {"print \"one\";", "\"one\""},
    ]

    Enum.each(values, fn {input, expected} ->
      assert capture_io(fn ->
        Eval.eval_program(input)
      end) == expected
    end)

  end

  test "Eval Assign" do
    assert false, message: "to-do eval Assign"
  end

  test "Eval Stmt" do
    values = [
      {"(2 + 1);", 3.0},
      {"true;", true},
      {"(2 + (1 - 3));", 0.0},
      {"-0;", 0.0},
      {"\"one\";", "\"one\""},
    ]

    Enum.each(values, fn {input, expected} ->
      output = Eval.eval_program(input)
      assert elem(output, 1) == expected
    end)

  end

  test "eval VarDecl" do
    values = [
      {"var a = 2;", "a", 2.0},
    ]

    Enum.each(values, fn {input, var, value} ->
      {env, _} = Eval.eval_program(input)
      assert Environment.contains(env, var) == true
      assert Environment.get(env, var) == value
    end)
    
  end

end