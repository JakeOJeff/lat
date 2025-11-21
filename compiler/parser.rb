DefNode     = Struct.new(:name, :args, :body)
IntegerNode = Struct.new(:value)
CallNode    = Struct.new(:name, :arg_expr)
VarRefNode  = Struct.new(:value)
VarAssignNode = Struct.new(:name, :value)

class Parser
  def initialize(tokens)
    @tokens = tokens
  end

  def parse
    if peek(:def)
      parse_def
    else
      parse_statement
    end
  end

  def parse_def
    consume(:def)
    name = consume(:identifier).value
    args = parse_args
    body = parse_statement
    consume(:end)
    DefNode.new(name, args, body)
  end

  def parse_statement
    if peek(:local)
      parse_var_assign
    else
      parse_expr
    end
  end

  def parse_var_assign
    consume(:local)
    name = consume(:identifier).value
    consume(:equal)
    value = parse_expr
    VarAssignNode.new(name, value)
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
    args = []
    unless peek(:cparen)
      args << parse_expr
      while peek(:comma)
        consume(:comma)
        args << parse_expr
      end
    end
    consume(:cparen)
    args
  end

  def parse_var_ref
    VarRefNode.new(consume(:identifier).value)
  end

  def consume(type)
    token = @tokens.shift
    raise "Expected #{type}, got #{token.type}" unless token.type == type
    token
  end

  def peek(type, offset = 0)
    @tokens[offset]&.type == type
  end
end