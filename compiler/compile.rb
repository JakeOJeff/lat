
require_relative "tokenizer"
require_relative "parser"
require_relative "codegen"

input = File.read("examples/main.lat")

tokens = Tokenizer.new(input).tokenize
puts "--- TOKENS ---"
puts tokens.map(&:inspect).join("\n")

tree = Parser.new(tokens).parse
puts "--- AST ---"
p tree

generated = Generator.new.generate(tree)
puts "--- LUA OUTPUT ---"
puts generated