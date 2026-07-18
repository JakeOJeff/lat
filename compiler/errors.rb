class LatSyntaxError < StandardError
  attr_reader :line, :column
  def initialize(message, line: nil, column: nil)
    @line = line
    @column = column
    super(message)
  end
end
