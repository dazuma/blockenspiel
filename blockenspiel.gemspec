::Gem::Specification.new do |s_|
  s_.name = 'blockenspiel'
  s_.summary = 'Blockenspiel is a helper library designed to make it easy to implement DSL blocks.'
  s_.description = 'Blockenspiel is a helper library designed to make it easy to implement DSL blocks. It is designed to be comprehensive and robust, supporting most common usage patterns, and working correctly in the presence of nested blocks and multithreading.'
  s_.version = "#{::File.read('Version').strip}.build#{::Time.now.utc.strftime('%Y%m%d%H%M%S')}"
  s_.author = 'Daniel Azuma'
  s_.email = 'dazuma@gmail.com'
  s_.homepage = 'http://virtuoso.rubyforge.org/blockenspiel'
  s_.rubyforge_project = 'virtuoso'
  s_.required_ruby_version = '>= 1.8.7'
  s_.files = ::Dir.glob("lib/**/*.{rb,jar}") +
    ::Dir.glob("ext/**/*.{c,rb}") +
    ::Dir.glob("test/**/*.rb") +
    ::Dir.glob("*.rdoc") +
    ['Version']
  s_.extra_rdoc_files = ::Dir.glob("*.rdoc")
  s_.test_files = ::Dir.glob("test/**/tc_*.rb")
  s_.platform = ::Gem::Platform::RUBY
  s_.extensions = ::Dir.glob("ext/*/extconf.rb")
end
