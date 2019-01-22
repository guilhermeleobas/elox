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

      assert elem(output, 1) == [expected], message: "Eval Literal"
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

      assert elem(output, 1) == [expected]
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
    values = [
      {"var a; a = 2;", 
        %{"a" => 2}
      },
      {"var a; var b; var c; a = 2; b = 3; c = 4;", 
        %{"a" => 2.0, "b" => 3.0, "c" => 4.0}
      },
      {"var a = 2; var b; b = a; var c = b;",
        %{"a" => 2.0, "b" => 2.0, "c" => 2.0}
      }
    ]

    Enum.each(values, fn {input, map} ->
      {env, _} = Eval.eval_program(input)
      assert env.map == map
    end)
  end

  test "Eval Undefined Assign" do
    values = [
      {"a = 2;", "a"}, 
      {"var a = 3; b = 3;", "b"},
    ]
    Enum.each(values, fn {input, var} ->
      assert_raise EvalError, "Undefined variable #{var}", fn -> 
        Eval.eval_program(input)
      end
    end)
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
      assert elem(output, 1) == [expected]
    end)

  end

  test "eval VarDecl" do
    values = [
      {"var a = 2;", "a", 2.0},
      {"var a = 2; var b = 3;", "b", 3.0},
    ]

    Enum.each(values, fn {input, var, value} ->
      {env, _} = Eval.eval_program(input)
      assert Environment.contains(env, var) == true
      assert Environment.get(env, var) == value
    end)
    
  end

  test "eval Block" do
    program = """
    var a = "global a";
    var b = "global b";
    var c = "global c";
    {
      var a = "outer a";
      var b = "outer b";
      {
        var a = "inner a";
        print a;
        print b;
        print c;
      }
      print a;
      print b;
      print c;
    }
    print a;
    print b;
    print c;
    """

    output = """
    "inner a""outer b""global c""outer a""outer b""global c""global a""global b""global c"
    """ |> String.trim

    assert capture_io(fn ->
      Eval.eval_program(program)
    end) == output


    program_2 = """
    var global = "outside";
    {
      var local = "inside";
      print global + local;
    }
    """

    output_2 = "\"outside\"\"inside\""

    assert capture_io(fn ->
      Eval.eval_program(program_2)
    end) == output_2
  end

end