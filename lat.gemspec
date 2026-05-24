Gem::Specification.new do |s|
  s.name        = "lat"
  s.version     = "0.1.1"
  s.summary     = "A language that compiles to Lua/LÖVE2D"
  s.authors     = ["JakeOJeff"]
  s.homepage    = "https://github.com/JakeOJeff/lat"
  s.files       = Dir["compiler/**/*"]
  s.executables = ["lat"]
  s.required_ruby_version = '>= 4.0.3'
  s.license     = "MIT"
end
