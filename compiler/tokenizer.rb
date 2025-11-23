Token = Struct.new(:type, :value)

class Tokenizer

  TOKEN_TYPES = [
    [:local, /\bnat\b/],
    [:def, /\bcall\b/],
    [:end, /\bdone\b/],
    [:if, /\bif\b/],
    [:print, /\bprint\b/],
    [:return, /\breturn\b/],

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

    [:identifier, /\b[a-zA-Z]+\b/],
    [:string, /"([^"]*)"/],
    [:integer, /\b[0-9]+\b/],
    [:oparen, /\(/],
    [:cparen, /\)/],
    [:comma, /,/],


    # operators
    [:dequal, /==/],
    [:equal, /=/],
    [:divide, /\//],
    [:multiply, /\*/],
    [:plus, /\+/],
    [:minus, /\-/],
    [:newline, /\n+/],
    [:space, /[ \t]+/], 




  ]

  def initialize(code)
    @code = code
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
          return tokenize_token
        end
        @code = @code[value.length..-1]
        return Token.new(type, value)
      end
    end

    raise "Couldn't match token on #{@code.inspect}"
  end
end