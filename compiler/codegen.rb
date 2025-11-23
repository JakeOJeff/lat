class Generator
  def generate(node)
    if node.is_a?(Array)
      return node.map { |n| generate(n) }.join("\n")
    end 

    case node
    when DefNode
      body_code = 
        if node.body.is_a?(Array)
          node.body.map { |n| generate (n) }.join("\n  ")
        else
          generate(node.body)
        end

      "function %s(%s)\n  %s \nend" % [
        node.name,
        node.args.join(","),
        body_code
      ]

    when IfNode
      compiled = ""

      first = node.condition
      compiled << "if #{generate(first)} then\n"
      compiled << node.body.map { |n| generate (n) }.join("\n")

      node.elif_blocks.each do |c|
        compiled << "\nelseif #{generate(c.condition)} then\n"
        compiled << c.body.map { |n| generate (n) }.join("\n")
      end

      if node.else_body
        compiled << "\nelse\n"
        compiled << node.else_body.map { |n| generate (n) }.join("\n")
      end

      compiled << "\nend"
      compiled

    when WhileNode
      body_code = 
      if node.body.is_a?(Array)
        node.body.map{ |n| generate (n) }.join("\n")
      else
        generate(node.body)
      end

      "while %s do \n %s \nend" % [
        generate(node.statement),
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

        body_code = c.body.map { |b| generate(b) }.join("\n")
        compiled << " #{body_code}\n"

      end
      compiled << "end"
      compiled


    when CallNode
      "%s(%s)" % [
        node.name,
        node.arg_expr.map { |expr| generate(expr) }.join(",")
      ]

    when PrintNode
      "print(%s)" % [
        node.args.map { |expr| generate(expr) }.join(",")
      ]

    when VarAssignNode
      "local %s = %s" % [
        node.name,
        generate(node.value)
      ]

    when VarSetNode
      "%s = %s" % [
        node.name,
        generate(node.value)
      ]

    when BinOpNode
      if node.right.is_a?(AndOrListNode) && node.op == :dequal
        left = generate(node.left)
        parts = node.right.items.map{ |item| "#{left} == #{generate(item)}"}
        return "(#{parts.join(' or ')})"
      end
      "(#{generate(node.left)} #{OP_NAMESPACES[node.op]} #{generate(node.right)})"

    when LoveCallNode
      "love.%s.%s(%s)" % [
        node.namespace,
        node.name,
        node.args.map { |expr| generate(expr) }.join(",")
      ]

    when ReturnNode
      "return %s" % [
        generate(node.statement)
      ]

    when VarRefNode
      node.value

    when IntegerNode
      node.value.to_s

    when StringNode
      "\"%s\"" % [
        node.value
      ]

    else
      raise "Unknown node type: #{node.class}"
    end
  end
end