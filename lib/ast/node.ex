# This piece of code was inspired by fabrik42 lang implementation
# in elixir.
# https://github.com/fabrik42/writing_an_interpreter_in_elixir/blob/master/lib/monkey/ast/node.ex

defprotocol Lox.Ast.Node do
  @doc "Returns the lexeme associated with the node"
  # def node_lexeme(node)

  @doc "Returns the type associated with the node"
  # def node_type(node)
end