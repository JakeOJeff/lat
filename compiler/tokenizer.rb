class Tokenizer

  TOKEN_TYPES = [
    [:def, /\bcall\b/],
    [:end, /\bpop\b/],
    [:identifier, /\ba-zA-Z]+\b/],
    [:integer, /\b[0-9]+\b/],
    [:oparen, /\(/],
    [:cparen, /\)/],
  ]
  def initialize(code)
    @code = code
  end

  def tokenize
    until @code.empty?
      TOKEN_TYPES.each do 
    end
  end
end

tokens = Tokenizer.new(File.read("examples/main.lat")).tokenize 
p tokens