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
        node.arg_expr.map { |expr| generate(expr) }.join(",")
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
      
    when VarRefNode
      node.value

    when IntegerNode
      node.value.to_s

    else
      raise "Unknown node type: #{node.class}"
    end
  end
end