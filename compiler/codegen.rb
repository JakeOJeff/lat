class Generator

  def generate_statement(node)
    code = generate(node)
    line = node.instance_variable_get(:@lat_line) if node.respond_to?(:instance_variable_get)
    line ? "--[[@#{line}]]#{code}" : code
  end

  def generate_arguments(args)
    args.map { |expr| generate(expr) }.join(",")
  end

  def generate_param_names(names)
    names.join(",")
  end

  def generate(node)
    if node.is_a?(Array)
      return node.map { |n| generate_statement(n) }.join("\n")
    end 

    case node
    
    when ImportNode
        "require(\"#{node.location}\")"
        
    when ClassNode
      out = []
      out << "local #{node.name} = {}"
      out << "#{node.name}.__index = #{node.name}"

      out << ""

      # entry point constructor
      out << "function #{node.name}:new()"
      out << "  local instance = setmetatable({}, self)"
      node.body.each do |stmt|
        if stmt.is_a?(VarAssignNode)
          out << " instance.#{stmt.name} = #{generate(stmt.value)}"
        else
          out << "#{generate(stmt)}"
        end
      end
      
      out << "  return instance"
      out << "end"
      out << ""

      #methods
      node.defs.each do |d|
        out << generate(d)
        out << ""
      end
     
      out.join("\n")
    when ClassDefNode
      body_code = generate(node.body)
     "function %s(%s)\n  %s\nend" % [node.name, generate_param_names(node.args), body_code]

    when DefNode
      body_code = generate(node.body)

      "function #{node.type == "love"? "love." : ""}%s(%s)\n  %s \nend" % [
        node.name,
        generate_param_names(node.args),
        body_code
      ]

    when IfNode
      compiled = ""

      first = node.condition
      compiled << "if #{generate(first)} then\n  "
      compiled << generate(node.body)

      node.elif_blocks.each do |c|
        compiled << "\nelseif #{generate(c.condition)} then\n  "
        compiled << generate(c.body)
      end

      if node.else_body
        compiled << "\nelse\n  "
        compiled << generate(node.else_body)
      end

      compiled << "\nend\n"
      compiled

    when WhileNode
      body_code = generate(node.body)

      "while %s do \n %s \nend" % [
        generate(node.statement),
        body_code
      ]

    when ForNode
      body_code = generate(node.body)

      increment = ", #{node.step.nil? ? "" : generate(node.step)}"
      "for %s = %s, %s%s do\n %s \nend"  % [
        generate(node.var),
        generate(node.start),
        generate(node.stop),
        increment,
        body_code
      ]

    when ForPairNode
      body_code = generate(node.body)
      "for %s, %s in pairs(%s) do\n %s \nend" % [
        node.key,
        node.val,
        generate(node.t),
        body_code
      ]

    when ForPairNode
      body_code = generate(node.body)

      "for %s, %s in ipairs(%s) do\n %s \nend" % [
        generate(node.index),
        generate(node.val),
        generate(node.t),
        body_code
      ]

    when SwitchNode
      compiled = ""
      node.cases.each_with_index do |c, i|
        if i == 0
          compiled << "if #{generate(c.match)} == #{generate(node.value)} then\n"
        else
          compiled << "elseif #{generate(c.match)} == #{generate(node.value)} then\n"
        end

        body_code = generate(c.body)
        compiled << " #{body_code}\n"

      end
      compiled << "end\n"
      compiled


    when CallNode
      "%s(%s)" % [
        node.name,
         generate_arguments(node.arg_expr)
      ]

    when PrintNode
      "print(%s)" % [
        generate_arguments(node.args)
      ]

    when VarAssignNode
      "local %s = %s" % [
        node.name,
        generate(node.value)
      ]

    when VarSetNode
      "%s = %s" % [
        node.children.join("."),
        generate(node.value)
      ]

    when BinOpNode
      if node.right.is_a?(AndOrListNode) && node.op == :dequal
        left = generate(node.left)
        parts = node.right.items.map{ |item| "#{left} == #{generate(item)}"}
        return "(#{parts.join(' or ')})"
      end
      "(#{generate(node.left)} #{OP_NAMESPACES[node.op]} #{generate(node.right)})"

    when SelfNode
      selfstring = "self#{node.type}#{node.name}"
    
      if !node.args.empty?
        args_string = generate_arguments(node.args)
        selfstring += "(#{args_string})"
      else
        selfstring += " = %s" % [
          generate(node.value)
        ]
      end
      selfstring

    when LoveCallNode
      "love.%s.%s(%s)" % [
        node.namespace,
        node.name,
        generate_arguments(node.args)
      ]

    when ReturnNode
      "return %s" % [
        generate(node.statement)
      ]

    when VarRefNode
      node.value

    when IntegerNode
      node.value.to_s

    when FloatNode
      node.value.to_s

    when StringNode
      "\"%s\"" % [
        node.value
      ]
    
    when ArrayNode
      elements = generate_arguments(node.elements)
      "{#{elements}}"

    when ArrayAccessNode
      "#{node.name}[#{generate(node.index)}]"

    else
      raise "Unknown node type: #{node.class}"
    end
  end
end