DefNode     = Struct.new(:name, :args, :body)
IntegerNode = Struct.new(:value)
CallNode    = Struct.new(:name, :arg_expr)
VarRefNode  = Struct.new(:value)
VarAssignNode = Struct.new(:name, :value)
VarSetNode = Struct.new(:name, :value)
BinOpNode = Struct.new(:left, :op, :right)

LoveCallNode = Struct.new(:namespace, :name, :args)


LOVE_NAMESPACES = {
  lgraphics: "graphics",
  laudio: "audio",
  ldata: "data",
  levent: "event",
  lfilesystem: "filesystem"
  lfont: "font",
  limage: "image",
  ljoystick: "joystick",
  lmouse: "mouse",
  lkeyboard: "keyboard"
}

class Parser
  def initialize(tokens)
    @tokens = tokens
  end

  def parse
    # if peek(:def)
    #   parse_def
    # else
    #   parse_statement
    # end
    statements = []
    while @tokens.any?
      skip_newlines
      break if @tokens.empty?
      statements << parse_statement
      skip_newlines
    end
    statements
  end

  def skip_newlines
    consume(:newline) while peek(:newline)
  end

  def parse_def
    consume(:def)
    name = consume(:identifier).value
    args = parse_args

    skip_newlines
    body = []

    until peek(:end)
      body << parse_statement
      skip_newlines
    end
    consume(:end)
    DefNode.new(name, args, body)
  end

  def parse_statement
    if peek(:def)
      parse_def
    elsif peek(:local)
      parse_var_assign
    elsif peek(:identifier) && peek(:equal, 1)
      parse_var_set
    else
      parse_expr
    end
  end

  def parse_var_set
    name = consume(:identifier).value
    consume(:equal)
    value = parse_expr
    VarSetNode.new(name, value)
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
    left = parse_term

    while peek(:plus)
      consume(:plus)
      right = parse_term
      left = BinOpNode.new(left, :plus, right)
    end
    
    left
  end

  def parse_term
    if peek(:integer)
      parse_int

    elsif peek(:identifier) && peek(:oparen, 1)
      parse_call

    elsif peek(:identifier)
      parse_var_ref

    elsif peek(:oparen)
      consume(:oparen)
      expr = parse_expr
      consume(:cparen)
      expr

    elsif LOVE_NAMESPACES.keys.include?(peek_type)
      parse_love_call
    else
      raise "Unexpected token #{peek(0).inspect} in term"
    end
  end

  def parse_int
    IntegerNode.new(consume(:integer).value.to_i)
  end

  def parse_love_call
    prefix = @tokens.shift.type
    namespace = LOVE_NAMESPACES[prefix]

    name = consume(:identifier).value
    args = parse_arg_expr

    LoveCallNode.new(namespace, name, args)
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

  def peek_type(offset = 0)
    @tokens[offset]&.type
  end
end