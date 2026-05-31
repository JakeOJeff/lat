DefNode  = Struct.new(:type, :name, :args, :body)
ClassNode = Struct.new(:name, :defs, :body )
ClassDefNode = Struct.new(:name, :args, :body)

IfNode = Struct.new(:condition, :body, :elif_blocks, :else_body)
ElifBlock = Struct.new(:condition, :body)

ImportNode = Struct.new(:location)

WhileNode = Struct.new(:statement, :body)
ForNode = Struct.new(:var, :start, :stop, :step, :body)
ForPairNode = Struct.new(:key, :val, :t, :body)
ForIPairNode = Struct.new(:index, :val, :t, :body)

IntegerNode = Struct.new(:value)
FloatNode = Struct.new(:value)
StringNode = Struct.new(:value)

CallNode    = Struct.new(:name, :arg_expr)
VarRefNode  = Struct.new(:value)
VarAssignNode = Struct.new(:name, :value)
VarSetNode = Struct.new(:name, :value)
BinOpNode = Struct.new(:left, :op, :right)
PrintNode = Struct.new(:args)
ReturnNode = Struct.new(:statement)
AndOrListNode = Struct.new(:items)
SwitchNode = Struct.new(:value, :cases)
CaseNode = Struct.new(:match, :body)

ArrayNode = Struct.new(:elements)
ArrayAccessNode = Struct.new(:name, :index)

LoveCallNode = Struct.new(:namespace, :name, :args)
SelfNode = Struct.new(:name, :type, :args, :value)

ErrorCallNode = Struct.new()


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
    # statements << ErrorCallNode.new()
    statements
  end

  def parse_statement

    skip_newlines
    return nil if peek(:end)

    if peek(:import) then
      parse_import
    elsif peek(:class) then
      parse_class
    elsif peek(:def)
      parse_def
    elsif peek(:if)
      parse_if
    elsif peek(:while)
      parse_while
    elsif peek(:for)
      parse_for
    elsif peek(:forpairs)
      parse_forpairs
    elsif peek(:foripairs)
      parse_foripairs
    elsif peek(:switch)
      parse_switch
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

  def skip_newlines
    consume(:newline) while peek(:newline)
  end

  def parse_import
    consume(:import)
    location = consume(:string).value

    ImportNode.new(location)
  end

  def parse_class
    consume(:class)
    name = consume(:identifier).value
    
    skip_newlines

    defs = []
    body = []
    until peek(:end)
      if peek(:def)
        defs << parse_class_def(name)
      else
        body << parse_statement
      end
      skip_newlines
    end
    consume (:end)
    ClassNode.new(name, defs, body)

  end

  def parse_class_def(name)
    consume(:def)
    name = "#{name}:#{consume(:identifier).value}"
    args = parse_args
    body = parse_block

    consume(:end)
    ClassDefNode.new(name, args, body)
  end

  def parse_def
    consume(:def)
    type = "normal"
    if peek(:love)
      consume(:love)
      type = "love"
      consume(:dot)
    end
    name = consume(:identifier).value
    args = parse_args

    body = parse_block
    consume(:end)
    DefNode.new(type, name, args, body)
  end


  def parse_if
    consume(:if)
    condition = parse_expr
    skip_newlines
    if_body = []
    while !peek(:elif) && !peek(:else) && !peek(:end)
      if_body << parse_statement
      skip_newlines
    end

    elif_blocks = []
    while peek(:elif)
      consume(:elif)
      elif_condition = parse_expr
      skip_newlines

      elif_body = []
      while !peek(:elif) && !peek(:else) && !peek(:end)
        elif_body << parse_statement
        skip_newlines
      end

      elif_blocks << ElifBlock.new(elif_condition, elif_body)
    end

    else_body = nil
    if peek(:else)
      consume(:else)
      skip_newlines

      else_body = parse_block

    end

    consume(:end)

    IfNode.new(condition, if_body, elif_blocks, else_body)
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

    body = parse_block

    consume(:end)
    WhileNode.new(statement, body)
  end

  def parse_for
    consume(:for)
    var = parse_expr
    consume(:equal)
    start = parse_expr
    consume(:comma)
    stop = parse_expr

    step = nil
    if peek(:comma) 
      consume(:comma)
      step = parse_expr
    end
    body = parse_block

    consume(:end)
    ForNode.new(var, start, stop, step, body)

  end

  def parse_forpairs
    consume(:forpairs)
    key = consume(:identifier).value
    consume(:comma)
    val = consume(:identifier).value
    consume(:in)
    t = parse_expr
    body = parse_block
    consume(:end)

    ForPairNode.new(key, val, t, body)
  end
  
  
  def parse_foripairs
    consume(:foripairs)
    index = consume(:identifier).value
    consume(:comma)
    val = consume(:identifier).value
    consume(:in)
    t = parse_expr
    body = parse_block
    consume(:end)

    ForIPairNode.new(index, val, t, body)
  end

  def parse_switch
    consume(:switch)
    value = parse_expr
    skip_newlines

    cases = []

    while peek(:to)
      consume(:to)
      match = parse_expr
      skip_newlines
    
      body = []

      until peek(:to) || peek(:end)
        body << parse_statement
        skip_newlines
      end

      cases << CaseNode.new(match, body)
    end

    consume(:end)
    SwitchNode.new(value, cases)
  end

  def parse_print
    consume(:print)
    args = parse_arg_expr
    PrintNode.new(args)
  end

  def parse_var_assign
    consume(:local)
    name = consume(:identifier).value
    consume(:equal)
    value = parse_expr
    VarAssignNode.new(name, value)
  end

  def parse_var_set
    name = consume(:identifier).value
    consume(:equal)
    value = parse_expr
    VarSetNode.new(name, value)
  end

  def parse_return
    consume(:return)
    statement = parse_expr
    ReturnNode.new(statement)
  end

  def parse_expr
    left = parse_additive

    while peek(:dequal)
      op = consume(:dequal)
      right = parse_additive
      left = BinOpNode.new(left, op.type, right)
    end

    left
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

  def parse_block
    skip_newlines
    body = []

    until peek(:end)
      body << parse_statement
      skip_newlines
    end
    body
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


  def parse_term
    skip_newlines
    if peek(:integer)
      IntegerNode.new(consume(:integer).value.to_i)

    elsif peek(:float)  
      FloatNode.new(consume(:float).value.to_f)

    elsif peek(:identifier) && peek(:oparen, 1)
      parse_call

    elsif peek(:identifier) && peek(:lbracket, 1)
      parse_array_access

    elsif peek(:lbrace)
      parse_array

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
      until peek(:identifier) || peek(:dequal)
        break
      end

      if !peek(:identifier) && peek(:or) || peek(:and)
        while peek(:or)
          consume(:or)
          items << parse_expr
        end
        while peek(:and)
          consume(:and)
          items << parse_expr
        end
        consume(:cparen)
        return AndOrListNode.new(items)
      end

      expr = first
      consume(:cparen)
      expr
    elsif peek(:self)
      parse_self_node




    elsif LOVE_NAMESPACES.keys.include?(peek_type)
      parse_love_call
    else
      raise "Unexpected token #{@tokens[0].inspect} in term"

    end
  end



  def parse_love_call
    prefix = @tokens.shift.type
    namespace = LOVE_NAMESPACES[prefix]

    name = @tokens.shift.value
    
    args = parse_arg_expr

    LoveCallNode.new(namespace, name, args)
  end

  def parse_self_node
    consume(:self)
    
    type = ""
    if peek(:dot)
      consume(:dot)
      type = "."
    elsif peek(:colon)
      consume(:colon)
      type = ":"
    end

    name = consume(:identifier).value

    if peek(:oparen)
      args = parse_arg_expr # parse args are for func defs and parse args expr is for call
    else
      args = []
    end

    if (type == ".") && peek(:equal)
      consume(:equal)
      value = parse_expr
    end
      
    SelfNode.new(name, type, args, value)
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

  def parse_array
    consume(:lbrace)
    skip_newlines
    elements = []
    unless peek(:rbrace)
      elements << parse_expr
      skip_newlines
      while peek(:comma)
        consume(:comma)
        skip_newlines
        elements << parse_expr
        skip_newlines
      end
    end
    skip_newlines
    consume(:rbrace)
    ArrayNode.new(elements)
  end

  
  def parse_array_access
    name = consume(:identifier).value
    consume(:lbracket)
    index = parse_expr
    consume(:rbracket)
    ArrayAccessNode.new(name, index)
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
