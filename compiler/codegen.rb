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
      body_code = 
      if node.body.is_a?(Array)
        node.body.map { |n| generate (n) }.join("\n")
      else
        generate(node.body)
      end

      "if %s then %s end" % [
        generate(node.statement),
        body_code
      ]

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