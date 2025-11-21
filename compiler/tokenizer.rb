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
      @code = @code.strip
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
      raise RuntimeError.new(
        "Couldn't match token on #{@code.inspect}"
      )
  end

end

class Parser
  def initialize(tokens)
    @tokens = tokens
  end

  def parse
    parse_def

  end

  def parse_def
    consume(:def)
    name = consume(:identifier).value
    args = parse_args
    body = parse_expr
    consume(:end)
    DefNode.new(name, args, body)
  end

  def parse_args
    consume(:oparen)
    consume(:cparen)
    []
  end

  def parse_expr
    parse_int
  end

  def parse_int
    IntegerNode.new(consume(:integer).value.to_i)
  end

  def consume(type)
    token = @tokens.shift
    if token.type == type
      token
    else
      raise RuntimeError.new(
        "Expected token type #{type.inspect} but received #{token.type.inspect}"
      )
    end
  end

end

DefNode = Struct.new(:name, :args, :body)
IntegerNode = Struct.new(:value)

Token = Struct.new(:type, :value)
tokens = Tokenizer.new(File.read("examples/main.lat")).tokenize 
puts tokens.map(&:inspect).join("\n")
tree = Parser.new(tokens).parse
p tree