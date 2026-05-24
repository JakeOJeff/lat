#!/usr/bin/env ruby

require_relative "tokenizer"
require_relative "parser"
require_relative "codegen"

if ARGV.empty?
    puts "Usage: lat <input.lat> [output.lua]"
    exit 1
end

def detect_os
    host = RbConfig::CONFIG["host_os"]
    return :windows if host =~ /mswin|mingw|cygwin/
    return :macos if host =~ /darwin/
    return :arch if File.exist?("/etc/arch-release")
    return :debian if File.exist?("/etc/debian_version")
    return :fedora if File.exist?("/etc/fedora-release")
    :linux
end

def love_installed?
    if detect_os == :windows
        common_paths = [
            "C:/Program Files/LOVE/love.exe",
            "C:/Program Files (x86)/LOVE/love.exe",
            ENV["LOVE_PATH"].to_s
        ]
        common_paths.any? { |p| File.exist?(p) }
    else
        system("love --version > /dev/null 2>&1")
    end
end


def find_love
    unless love_installed?

    end

    candidates = [
        "love",
        "C:/Program Files/LOVE/love.exe",
        "C:/Program Files (x86)/LOVE/love.exe",
        ENV["LOVE_PATH"]
    ].compact

    candidates.each do |path|
        return path if system("where #{path} >nul 2>&1") || File.exist?(path.to_s)
    end

    puts "Error: LOVE2D not found. Install it from https://love2d.org or set LOVE_PATH env variable."
    exit 1
end
skip_run = false
love = find_love()

if ARGV[0] == "run"
    latcDir = File.join(Dir.pwd, ".latc")
    unless Dir.exist?(latcDir)
        puts "Error: no .latc folder foound. Compile something first \n 'lat <input.lat> [main.lua]"
        exit 1
    end

    unless File.exist?(File.join(latcDir, "main.lua"))
        puts "Error: .latc exists but no main.lua found"
        exit 1
    end
    exec(love, latcDir)
elsif ARGV[0] == "build"
    ARGV.shift
    skip_run = true
end
inputFile  = ARGV[0] || "main.lat"

unless File.exist?(inputFile)
    puts "Error: fil `#{inputFile}` not found"
    exit 1
end

latcDir = File.join(Dir.pwd, ".latc")
Dir.mkdir(latcDir) unless Dir.exist?(latcDir)

if RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
  system("attrib +h #{latcDir}") # -h to unhide
end

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

exec(love, latcDir) unless skip_run

# ln -s "$(pwd)/compiler/compile.rb" /usr/local/bin/lat