#!/usr/bin/env ruby

require_relative "tokenizer"
require_relative "parser"
require_relative "codegen"
require_relative "errors"

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

OS = detect_os

def love_installed?
    if OS == :windows
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

def install_love
    puts "[lat] Love2D not found, attempting to install"
    print "Do you want to install LOVE2D? (y/n)"
    answer = $stdin.gets.chomp.downcase

    if %w[y yes].include?(answer.downcase)
        puts "installing love..."

        case OS
        when :arch
            system("sudo pacman -S --noconfirm love")
        when :debian
            system("sudo apt-get install -y love")
        when :fedora
            system("sudo dnf install -y love")
        when :macos
            if system("which brew > /dev/null 2>&1")
                system("brew install love")
            else
                puts "[lat] Homebrew not found. Install LOVE2D from https://love2d.org"
                exit 1
            end
        when :windows
            puts "[lat] Please install LOVE2D from https://love2d.org"
            puts "[lat] Set LOVE_PATH to the love.exe location:"
            puts '[lat]   setx LOVE_PATH "C:\\Program Files\\LOVE\\love.exe"'
        else
            puts "[lat] Can't auto-install on this system. Install LÖVE2D from https://love2d.org"
            exit 1
        end
    else
        puts "exiting..."
        exit 1
    end

end


def find_love
    install_love unless love_installed?

    if OS == :windows
        candidates = [ENV["LOVE_PATH"], "C:/Program Files/LOVE/love.exe", "C:/Program Files (x86)/LOVE/love.exe"].compact
        candidates.each { |p| return p if File.exist?(p) }
    else
        ["love", "love2d"].each do |cmd|
            return cmd if system("which #{cmd} > /dev/null 2>&1")
        end
    end

    puts "Error: LOVE2D not found. Install it from https://love2d.org or set LOVE_PATH env variable."
    exit 1
end
skip_run = false

if ARGV[0] == "run"
    latcDir = File.join(Dir.pwd, ".latc")
    unless Dir.exist?(latcDir)
        puts "Error: no .latc folder found. Compile something first \n 'lat <input.lat> [main.lua]"
        exit 1
    end

    unless File.exist?(File.join(latcDir, "main.lua"))
        puts "Error: .latc exists but no main.lua found"
        exit 1
    end
    love = find_love()
    exec(love, latcDir)
elsif ARGV[0] == "build"
    ARGV.shift
    skip_run = true
end
inputFile  = ARGV[0] || "main.lat"

unless File.exist?(inputFile)
    puts "Error: file `#{inputFile}` not found"
    exit 1
end

latcDir = File.join(Dir.pwd, ".latc")
Dir.mkdir(latcDir) unless Dir.exist?(latcDir)

if RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
  system("attrib +h #{latcDir}") # -h to unhide
end

inputDir = File.dirname(inputFile)
basename = File.basename(inputFile, ".*")
outputFile = File.join(latcDir, basename == "main" ? "main.lua" : "#{basename}.lua")
confOutputFile = File.join(latcDir, "conf.lua")

confPath = File.join(inputDir, "conf.lat")
confInput = File.read(confPath) if File.exist?(confPath)

input = File.read(inputFile)
confInput = File.read(confPath) if File.exist?(confPath)

tokens = Tokenizer.new(input).tokenize
confTokens = Tokenizer.new(confInput).tokenize if confInput
# puts "--- TOKENS ---"
# puts tokens.map(&:inspect).join("\n")

tree = Parser.new(tokens).parse
confTree = Parser.new(confTokens).parse if confTokens
# puts "--- AST ---"
# p tree




generated = Generator.new.generate(tree)
confGenerated = Generator.new.generate(confTree) if confTree
# puts "--- LUA OUTPUT ---"
# puts generated

def build_source_map(lua_source)
    map = {}
    clean_lines = lua_source.split("\n", -1).each_with_index.map do |line, idx|
        if line =~ /\A--\[\[@(\d+)\]\](.*)\z/m
            map[idx + 1] = $1.to_i 
            $2
        else
            line
        end
    end
    [clean_lines.join("\n"), map]
end

def build_lat_shim(basename, source_map)
  table_entries = source_map.map { |k, v| "[#{k}]=#{v}" }.join(",")
  <<~LUA
    local _LAT_SOURCE_MAP_T = { #{table_entries} }
    local _LAT_FILE = "#{basename}.lat"

    local function _lat_remap(text)
      return (text:gsub("#{basename}%.lua:(%d+)", function(n)
        local mapped = _LAT_SOURCE_MAP_T[tonumber(n)]
        return mapped and (_LAT_FILE .. ":" .. mapped) or ("#{basename}.lua:" .. n)
      end))
    end

    if not _G.__lat_default_errorhandler then
      _G.__lat_default_errorhandler = love.errorhandler
    end

    function love.errorhandler(msg)
      return _G.__lat_default_errorhandler(_lat_remap(tostring(msg)))
    end

  LUA
end


generated, source_map = build_source_map(generated)
generated = build_lat_shim(basename, source_map) + generated

confGenerated, _conf_source_map = build_source_map(confGenerated) if confGenerated

File.open(outputFile, 'w') { |file| file.write(generated) }
File.open(confOutputFile, 'w') { |file| file.write(confGenerated) } if confGenerated
exec(find_love(), latcDir) unless skip_run

# ln -s "$(pwd)/compiler/compile.rb" /usr/local/bin/lat