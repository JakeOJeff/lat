DefNode  = Struct.new(:name, :args, :body)
IfNode = Struct.new(:statement, :body)
WhileNode = Struct.new(:statement, :body)
IntegerNode = Struct.new(:value)
StringNode = Struct.new(:value)
CallNode    = Struct.new(:name, :arg_expr)
VarRefNode  = Struct.new(:value)
VarAssignNode = Struct.new(:name, :value)
VarSetNode = Struct.new(:name, :value)
BinOpNode = Struct.new(:left, :op, :right)
PrintNode = Struct.new(:args)
ReturnNode = Struct.new(:statement)
AndOrListNode = Struct.new(:items)

LoveCallNode = Struct.new(:namespace, :name, :args)


LOVE_NAMESPACES = {
  lgraphics: "graphics",
  laudio: "audio",
  ldata: "data",
  levent: "event",
  lfilesystem: "filesystem",
  lfont: "font",
  limage: "image",
  ljoystick: "joystick",
  lmouse: "mouse",
  lkeyboard: "keyboard"
}

OP_NAMESPACES = {
  dequal: "==",
  equal: "=",
  divide: "/",
  multiply: "*",
  plus: "+",
  minus: "-",

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

  def parse_return
    consume(:return)
    statement = parse_expr
    ReturnNode.new(statement)
  end

  def parse_if
    consume(:if)

    if peek(:oparen)
      consume(:oparen)
      statement = parse_expr
      consume(:cparen)
    else
      statement = parse_expr
    end
    skip_newlines
    body = []

    until peek(:end)
      body << parse_statement
      skip_newlines
    end
    consume(:end)
    IfNode.new(statement, body)
  end

  def parse_while
    consume(:while)

    if peek(:oparen)
      consume(:oparen)
      statement = parse_expr
      consume(:cparen)
    else
      statement = parse_expr
    end

    skip_newlines
    body = []

    until peek(:end)
      body << parse_statement
      skip_newlines
    end

    consume(:end)
    WhileNode.new(statement, body)
  end


  def parse_print
    consume(:print)
    args = parse_arg_expr
    PrintNode.new(args)
    
  end

  def parse_statement

    skip_newlines
    return nil if peek(:end)

    if peek(:def)
      parse_def
    elsif peek(:if)
      parse_if
    elsif peek(:while)
      parse_while
    elsif peek(:print)
      parse_print
    elsif peek(:local)
      parse_var_assign
    elsif peek(:identifier) && peek(:equal, 1)
      parse_var_set
    elsif peek(:return)
      parse_return
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
    parse_equality
  end
  def parse_equality
    left = parse_additive

    while peek(:dequal)
      op = consume(:dequal)
      right = parse_additive
      left = BinOpNode.new(left, op.type, right)
    end

    left
  end

  def parse_additive
    left = parse_multiplicative

    while peek(:plus) || peek(:minus) 
      op = @tokens.shift.type
      right = parse_multiplicative
      left = BinOpNode.new(left, op, right)
    end
    left
  end
  
  def parse_multiplicative
    left = parse_term

    while peek(:multiply) || peek(:divide)
      op = @tokens.shift.type
      right = parse_term
      left = BinOpNode.new(left, op, right)
    end
    left
  end
  # def parse_operators
  #   left = parse_term

  #   left = parse_op(left, :divide)
  #   left = parse_op(left, :multiply)
  #   left = parse_op(left, :plus)
  #   left = parse_op(left, :minus)

  #   left
  # end

  # def parse_op(left, operator)

  #   while peek(operator)
  #     consume(operator)
  #     right = parse_term
  #     left = BinOpNode.new(left, operator, right)
  #   end
  #   left
  
  # end

  def parse_term
    if peek(:integer)
      IntegerNode.new(consume(:integer).value.to_i)

    elsif peek(:identifier) && peek(:oparen, 1)
      parse_call

    elsif peek(:identifier)
      VarRefNode.new(consume(:identifier).value)

    elsif peek(:string)
      strVal = consume(:string).value
      StringNode.new(strVal[1..-2])

    elsif peek(:oparen)
      # consume(:oparen)
      # expr = parse_expr
      # consume(:cparen)
      # expr
      consume(:oparen)

      first = parse_expr
      items = [first]
      until peek(:identifier) && peek(:or) && peek(:dequal) && peek(:cparen) && peek(:plus)
        break
      end

      if !peek(:identifier) && peek(:or)
        while peek(:or)
          consume(:or)
          items << parse_expr
        end
        consume(:cparen)
        return AndOrListNode.new(items)
      end

      expr = first
      consume(:cparen)
      expr


    elsif LOVE_NAMESPACES.keys.include?(peek_type)
      parse_love_call
    else
      raise "Unexpected token #{@tokens[0].inspect} in term"

    end
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