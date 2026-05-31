class Generator
  def generate(node)
    if node.is_a?(Array)
      return node.map { |n| generate(n) }.join("\n")
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
      body_code = node.body.map { |n| generate(n) }.join("\n  ")
     "function %s(%s)\n  %s\nend" % [node.name, node.args.join(","), body_code]

    when DefNode
      body_code = 
        if node.body.is_a?(Array)
          node.body.map { |n| generate (n) }.join("\n  ")
        else
          generate(node.body)
        end

      "function #{node.type == "love"? "love." : ""}%s(%s)\n  %s \nend" % [
        node.name,
        node.args.join(","),
        body_code
      ]

    when IfNode
      compiled = ""

      first = node.condition
      compiled << "if #{generate(first)} then\n  "
      compiled << node.body.map { |n| generate (n) }.join("\n")

      node.elif_blocks.each do |c|
        compiled << "\nelseif #{generate(c.condition)} then\n  "
        compiled << c.body.map { |n| generate (n) }.join("\n")
      end

      if node.else_body
        compiled << "\nelse\n  "
        compiled << node.else_body.map { |n| generate (n) }.join("\n")
      end

      compiled << "\nend\n"
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

    when ForNode
      body_code = 
      if node.body.is_a?(Array)
        node.body.map{ |n| generate (n) }.join("\n")
      else
        generate(node.body)
      end
      increment = ", #{node.step.nil? ? "" : generate(node.step)}"
      "for %s = %s, %s%s do\n %s \nend"  % [
        generate(node.var),
        generate(node.start),
        generate(node.stop),
        increment,
        body_code
      ]

    when ForPairNode
      body_code = 
      if node.body.is_a?(Array)
        node.body.map{ |n| generate (n) }.join("\n")
      else
        generate(node.body)
      end
      "for %s, %s in pairs(%s) do\n %s \nend" % [
        generate(node.key),
        generate(node.val),
        generate(node.t),
        body_code
      ]

    when ForPairNode
      body_code = 
      if node.body.is_a?(Array)
        node.body.map{ |n| generate (n) }.join("\n")
      else
        generate(node.body)
      end
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

        body_code = c.body.map { |b| generate(b) }.join("\n")
        compiled << " #{body_code}\n"

      end
      compiled << "end\n"
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

    when SelfNode
      selfstring = "self#{node.type}#{node.name}"
    
      if !node.args.empty?
        args_string = node.args.map {|expr| generate(expr) }.join(",")
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

    when FloatNode
      node.value.to_s

    when StringNode
      "\"%s\"" % [
        node.value
      ]
    
    when ArrayNode
      elements = node.elements.map { |e| generate(e) }.join(", ")
      "{#{elements}}"

    when ArrayAccessNode
      "#{node.name}[#{generate(node.index)}]"

    # when ErrorCallNode
    #   <<~LUA
    #   local utf8 = require("utf8")

    #   local function error_printer(msg, layer)
    #     print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
    #   end

    #   function love.errorhandler(msg)
    #     msg = tostring(msg)

    #     error_printer(msg, 2)

    #     if not love.window or not love.graphics or not love.event then
    #       return
    #     end

    #     if not love.graphics.isCreated() or not love.window.isOpen() then
    #       local success, status = pcall(love.window.setMode, 800, 600)
    #       if not success or not status then
    #         return
    #       end
    #     end

    #     -- Reset state.
    #     if love.mouse then
    #       love.mouse.setVisible(true)
    #       love.mouse.setGrabbed(false)
    #       love.mouse.setRelativeMode(false)
    #       if love.mouse.isCursorSupported() then
    #         love.mouse.setCursor()
    #       end
    #     end
    #     if love.joystick then
    #       -- Stop all joystick vibrations.
    #       for i,v in ipairs(love.joystick.getJoysticks()) do
    #         v:setVibration()
    #       end
    #     end
    #     if love.audio then love.audio.stop() end

    #     love.graphics.reset()
    #     local font = love.graphics.setNewFont(14)

    #     love.graphics.setColor(1, 1, 1)

    #     local trace = debug.traceback()

    #     love.graphics.origin()

    #     local sanitizedmsg = {}
    #     for char in msg:gmatch(utf8.charpattern) do
    #       table.insert(sanitizedmsg, char)
    #     end
    #     sanitizedmsg = table.concat(sanitizedmsg)

    #     local err = {}

    #     table.insert(err, "Error\n")
    #     table.insert(err, sanitizedmsg)

    #     if #sanitizedmsg ~= #msg then
    #       table.insert(err, "Invalid UTF-8 string in error message.")
    #     end

    #     table.insert(err, "\n")

    #     for l in trace:gmatch("(.-)\n") do
    #       if not l:match("boot.lua") then
    #         l = l:gsub("stack traceback:", "Traceback\n")
    #         table.insert(err, l)
    #       end
    #     end

    #     local p = table.concat(err, "\n")

    #     p = p:gsub("\t", "")
    #     p = p:gsub("%[string \"(.-)\"%]", "%1")

    #     local function draw()
    #       if not love.graphics.isActive() then return end
    #       local pos = 70
    #       love.graphics.clear(89/255, 157/255, 220/255)
    #       love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
    #       love.graphics.present()
    #     end

    #     local fullErrorText = p
    #     local function copyToClipboard()
    #       if not love.system then return end
    #       love.system.setClipboardText(fullErrorText)
    #       p = p .. "\nCopied to clipboard!"
    #     end

    #     if love.system then
    #       p = p .. "\n\nPress Ctrl+C or tap to copy this error"
    #     end

    #     return function()
    #       love.event.pump()

    #       for e, a, b, c in love.event.poll() do
    #         if e == "quit" then
    #           return 1
    #         elseif e == "keypressed" and a == "escape" then
    #           return 1
    #         elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
    #           copyToClipboard()
    #         elseif e == "touchpressed" then
    #           local name = love.window.getTitle()
    #           if #name == 0 or name == "Untitled" then name = "Game" end
    #           local buttons = {"OK", "Cancel"}
    #           if love.system then
    #             buttons[3] = "Copy to clipboard"
    #           end
    #           local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
    #           if pressed == 1 then
    #             return 1
    #           elseif pressed == 3 then
    #             copyToClipboard()
    #           end
    #         end
    #       end

    #       draw()

    #       if love.timer then
    #         love.timer.sleep(0.1)
    #       end
    #     end

    #   end
    #   LUA

    else
      raise "Unknown node type: #{node.class}"
    end
  end
end