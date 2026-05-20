#!/usr/bin/env ruby

require_relative "tokenizer"
require_relative "parser"
require_relative "codegen"

if ARGV.empty?
    puts "Usage: lat <input.lat> [output.lua]"
    exit 1
end

inputFile  = ARGV[0]

unless File.exist?(inputFile)
    puts "Error: fil `#{inputFile}` not found"
    exit 1
end

latcDir = File.join(Dir.pwd, ".latc")
Dir.mkdir(latcDir) unless Dir.exist?(latcDir)

basename = File.basename(inputFile, ".*")
outputFile = File.join(latcDir, basename == "main" ? "main.lua" : "#{basename}.lua")

input = File.read(inputFile)

tokens = Tokenizer.new(input).tokenize
# puts "--- TOKENS ---"
# puts tokens.map(&:inspect).join("\n")

tree = Parser.new(tokens).parse
# puts "--- AST ---"
# p tree

generated = Generator.new.generate(tree)
# puts "--- LUA OUTPUT ---"
# puts generated
File.open(outputFile, 'w') { |file| file.write(generated)}

exec("love", latcDir)


# ln -s "$(pwd)/compiler/compile.rb" /usr/local/bin/lat