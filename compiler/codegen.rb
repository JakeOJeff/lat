class Generator
  def generate(node)
    if node.is_a?(Array)
      return node.map { |n| generate(n) }.join("\n")
    end 

    case node
    when DefNode
      body_code = 
        if node.body.is_a?(Array)
          node.body.map { |n| generate (n) }.join("\n")
        else
          generate(node.body)
        end

      "function %s(%s) return %s end" % [
        node.name,
        node.args.join(","),
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
      "(#{generate(node.left)} + #{generate(node.right)})"

    when LoveCallNode
      "love.%s.%s(%s)" % [
        node.namespace,
        node.name,
        node.args.map { |expr| generate(expr) }.join(",")
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