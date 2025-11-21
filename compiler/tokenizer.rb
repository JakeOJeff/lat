class Tokenizer

  TOKEN_TYPES = [
    [:def, /\bcall\b/],
    [:end, /\bpop\b/],
    [:identifier, /\b[a-zA-Z]+\b/],
    [:integer, /\b[0-9]+\b/],
    [:oparen, /\(/],
    [:cparen, /\)/],
    [:comma, /,/]
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
    args = []
    if peek(:identifier)
      args << consume(:identifier).value
      while peek(:comma)
        consume(:comma)
        args << consume(:identifier).value
      end
    end
    consume(:cparen)
    args
  end

  def parse_expr
    if peek(:integer)
      parse_int
    elsif peek(:identifier) && peek(:oparen, 1)
      parse_call
    else
      parse_var_ref
    end
  end

  def parse_int
    IntegerNode.new(consume(:integer).value.to_i)
  end

  def parse_call
    name = consume(:identifier).value
    arg_expr = parse_arg_expr
    CallNode.new(name, arg_expr)
  end

  def parse_arg_expr
    consume(:oparen)
    arg_expr = []
    if !peek(:cparen)
      arg_expr << parse_expr
      while peek(:comma)
        consume(:comma)
        arg_expr << parse_expr
      end
    end
    consume(:cparen)
    arg_expr

  end

  def parse_var_ref
    VarRefNode.new(consume(:identifier).value)
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

  def peek(type, index = 0)
    @tokens.fetch(index).type == type
  end

end

DefNode = Struct.new(:name, :args, :body)
IntegerNode = Struct.new(:value)
CallNode = Struct.new(:name, :arg_expr)
VarRefNode = Struct.new(:value)

class Generator
  def generate(node)
    case node
    when DefNode
      "function %s(%s) return %s end" % [
        node.name,
        node.args.join(","),
        generate(node.body)
      ]
    when CallNode
      "%s(%s)" % [
        node.name,
        node.arg_expr.map { |expr| generate(expr) }.join(","),
      ]
    when VarRefNode
      node.value
    when IntegerNode
      node.value
    else
      raise RuntimeError.new("Unexpected node type: #{node.class}")
    end
  end
end


Token = Struct.new(:type, :value)
tokens = Tokenizer.new(File.read("examples/main.lat")).tokenize 
puts tokens.map(&:inspect).join("\n")
tree = Parser.new(tokens).parse
p tree

generated = Generator.new.generate(tree)
puts generated