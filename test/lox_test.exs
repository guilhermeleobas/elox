defmodule LoxTest do
  use ExUnit.Case
  doctest Lox

  test "get_program_text" do
    assert Lox.read_file('test/lox/hello.lox') == {:ok, """
    // Your first Lox program!
    print "Hello, world!";
    """
    }
  end
end
