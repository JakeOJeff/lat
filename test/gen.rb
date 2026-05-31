require_relative "helper"

class CodegenTest < Minitest::Test 
    def test_baseCompilation
        out = compile('print("hello")')
        refute_empty out
    end
end