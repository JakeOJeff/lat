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
    tokens = []
    until @code.empty?
      tokens << tokenize_token
    end
    tokens
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

Token = Struct.new(:type, :value)
tokens = Tokenizer.new(File.read("examples/main.lat")).tokenize 
puts tokens.map(&:inspect).join("\n")