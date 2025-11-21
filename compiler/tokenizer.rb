class Tokenizer

  TOKEN_TYPES = [
    [:def, /\bcall\b/],
    [:end, /\bpop\b/],
    [:identifier, /\b[a-zA-Z]+\b/],
    [:integer, /\b[0-9]+\b/],
    [:oparen, /\(/],
    [:cparen, /\)/],
  ]
  def initialize(code)
    @code = code
  end

  def tokenize
    until @code.empty?
      tokenize_token
    end
    def tokenize_token
      TOKEN_TYPES.each do |type, regex|
        regex = /\A(#{regex})/
        if @code =~ regex
          value = $1
          @code = @code[value.length..-1]
          return Token.new(type, value)
        end
      end
    end
    raise RuntimeError.new(
      "Couldn't match token on #{@code.inspect}"
    )
  end
end
Token = Struct.new(:type, :value)
tokens = Tokenizer.new(File.read("examples/main.lat")).tokenize 
p tokens