$LOAD_PATH.unshift File.expand_path("../compiler", __dir__)

require "minitest/autorun"
require "tokenizer"
require "parser"
require "codegen"

def compile(source)
    tokens = Tokenizer.new(source).tokenize 
    tree = Parser.new(tokens).parse 
    Generator.new.generate(tree)
end

def strip(str)
    str.strip.gsub(/\s+/, " ")
end