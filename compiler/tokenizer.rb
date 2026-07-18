Token = Struct.new(:type, :value, :line, :column)

class Tokenizer

  TOKEN_TYPES = [

      #love 
    [:lgraphics, /-G:/],
    [:laudio, /-A:/],
    [:ldata, /-D:/],
    [:levent, /-E:/],
    [:lfilesystem, /-FS:/],
    [:lfont, /-F:/],
    [:limage, /-I:/],
    [:ljoystick, /-J:/],
    [:lmouse, /-M:/],
    [:lkeyboard, /-K:/],
    [:love, /\blove\b/],
    
    [:local, /\bnat\b/],
    [:def, /\bcall\b/],
    [:end, /\bdone\b/],
    [:if, /\bif\b/],
    [:elif, /\belif\b/],
    [:else, /\belse\b/],

    [:while, /\bwhen\b/],
    [:for, /\bfor\b/],
    [:forpairs, /\beach\b/],
    [:foripairs, /\bseq\b/],

    [:print, /\bprint\b/],
    [:return, /\breturn\b/],
    [:or, /\bor\b/],
    [:and, /\band\b/],
    [:in, /\bas\b/],
    [:switch, /\bswitch\b/],
    [:to, /\bto\b/],
    [:class, /\bclass\b/],
    [:self, /\bself\b/],
    [:import, /\bbring\b/],



    # thingies
    [:identifier, /\b[a-zA-Z_][a-zA-Z0-9_]*\b/],
    [:string, /"([^"]*)"/],
    [:float, /(?:\d+\.\d*|\.\d+)/],
    [:integer, /\b\d+\b/],
    [:oparen, /\(/],
    [:cparen, /\)/],
    [:lbracket, /\[/],
    [:rbracket, /\]/],
    [:lbrace, /\{/],
    [:rbrace, /\}/],
    [:comma, /,/],
    [:dot, /\./],
    [:colon, /:/],

    # operators
    [:dequal, /==/],
    [:grequal, />=/],
    [:lequal, /<=/],
    [:greater, />/],
    [:lesser, /</],
    [:equal, /=/],
    [:divide, /\//],
    [:multiply, /\*/],
    [:plus, /\+/],
    [:minus, /\-/],
    [:newline, /\n+/],
    [:space, /[ \t]+/], 

  ]

  def initialize(code, filename = nil)
    @code = code
    @filename = filename
    @line = 1
    @column = 1
    # puts "Tokenizer initialized with: #{code.inspect}"
  end

  def tokenize
    tokens = []
    until @code.empty?
      tokens << tokenize_token
      # @code = @code.strip
    end
    tokens
  end

  def tokenize_token
    TOKEN_TYPES.each do |type, regex|
      anchored = /\A(#{regex})/
      
      if @code =~ anchored
        value = $1
        if type == :space
          @code = @code[value.length..-1]
          @column += value.length
          return tokenize_token
        end

        token = Token.new(type, value, @line)
        @code = @code[value.length..-1]

        if type == :newline
          @line += value.count("\n")
          @column = 1
        else
          @column += value.length
        end

        # return Token.new(type, value)
        return token
      end
    end

    snippet = @code.lines.first.to_s.chomp
    snippet = snippet[0, 30] + "..." if snippet.length > 30

    raise LatSyntaxError.new(
      "Unrecognized syntax near #{snippet.inspect}",
      line: @line,
      column: @column
    )

    # raise "Couldn't match token on #{@code.inspect}"
  end
end