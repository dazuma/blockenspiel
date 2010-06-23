# -----------------------------------------------------------------------------
# 
# Blockenspiel Rakefile
# 
# -----------------------------------------------------------------------------
# Copyright 2008-2010 Daniel Azuma
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------
;


require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rdoc'
require 'rdoc/rdoc'
require 'rdoc/generator/darkfish'

require ::File.expand_path("#{::File.dirname(__FILE__)}/lib/blockenspiel/version")


# Configuration

EXTRA_RDOC_FILES = ['README.rdoc', 'Blockenspiel.rdoc', 'History.rdoc', 'ImplementingDSLblocks.rdoc']


# Environment configuration

dlext_ = Config::CONFIG['DLEXT']
platform_ =
  case ::RUBY_DESCRIPTION
  when /^jruby\s/ then :jruby
  when /^ruby\s/ then :mri
  when /^rubinius\s/ then :rubinius
  else :unknown
  end


# Default task

task :default => [:clean, :rdoc, :package, :test]


# Clean task

CLEAN.include(['ext/blockenspiel/Makefile*', "**/*.#{dlext_}", "**/*.rbc", 'ext/blockenspiel/*.o', '**/*.jar', 'ext/blockenspiel/*.class', 'idslb_markdown.txt', 'doc', 'pkg'])


# Test task

task :test => :build
::Rake::TestTask.new('test') do |task_|
  task_.pattern = 'tests/tc_*.rb'
end


# RDoc task

::Rake::RDocTask.new do |task_|
  task_.main = 'README.rdoc'
  task_.rdoc_files.include(*EXTRA_RDOC_FILES)
  task_.rdoc_files.include(['lib/blockenspiel.rb', 'lib/blockenspiel/*.rb'])
  task_.rdoc_dir = 'doc'
  task_.title = "Blockenspiel #{::Blockenspiel::VERSION_STRING} documentation"
  task_.options << '--format=darkfish'
end


# Gem package task

task :package => [:build_jruby] do
  mkdir_p('pkg')
  
  # Common gemspec
  def create_gemspec
    ::Gem::Specification.new do |s_|
      s_.name = 'blockenspiel'
      s_.summary = 'Blockenspiel is a helper library designed to make it easy to implement DSL blocks.'
      s_.version = ::Blockenspiel::VERSION_STRING.dup
      s_.author = 'Daniel Azuma'
      s_.email = 'dazuma@gmail.com'
      s_.description = 'Blockenspiel is a helper library designed to make it easy to implement DSL blocks. It is designed to be comprehensive and robust, supporting most common usage patterns, and working correctly in the presence of nested blocks and multithreading.'
      s_.homepage = 'http://virtuoso.rubyforge.org/blockenspiel'
      s_.rubyforge_project = 'virtuoso'
      s_.required_ruby_version = '>= 1.8.7'
      s_.files = ::FileList['ext/**/*.{c,rb,java}', 'lib/**/*.{rb,jar}', 'tests/**/*.rb', '*.rdoc', 'Rakefile'].to_a
      s_.extra_rdoc_files = EXTRA_RDOC_FILES.dup
      s_.has_rdoc = true
      s_.test_files = FileList['tests/tc_*.rb']
      yield s_
    end
  end
  
  # Normal platform gemspec
  gemspec_ = create_gemspec do |s_|
    s_.platform = ::Gem::Platform::RUBY
    s_.extensions = ['ext/blockenspiel/extconf.rb']
  end
  ::Gem::Builder.new(gemspec_).build
  mv "blockenspiel-#{::Blockenspiel::VERSION_STRING}.gem", 'pkg'
  
  # JRuby gemspec
  gemspec_ = create_gemspec do |s_|
    s_.platform = 'java'
    s_.files += ['lib/blockenspiel_unmixer_jruby.jar']
  end
  ::Gem::Builder.new(gemspec_).build
  mv "blockenspiel-#{::Blockenspiel::VERSION_STRING}-java.gem", 'pkg'
end


# General build task

case platform_
when :jruby
  task :build => [:build_jruby]
when :mri
  task :build => [:build_mri]
else
  task :build
end


# Build tasks for MRI.
# These are available only if the current rake is running under MRI.
# They build the C extension for the current MRI.

if platform_ == :mri
  
  if ::RUBY_VERSION =~ /^1\.8\..*$/
    mri_version_suffix_ = '18'
  elsif ::RUBY_VERSION =~ /^1\.9\..*$/
    mri_version_suffix_ = '19'
  else
    raise "Unknown version of Matz Ruby Interpreter (#{::RUBY_VERSION})"
  end
  
  makefile_name_ = "Makefile#{mri_version_suffix_}"
  unmixer_general_name_ = "unmixer_mri.#{dlext_}"
  unmixer_name_ = "unmixer_mri#{mri_version_suffix_}.#{dlext_}"
  
  desc 'Ensures the MRI C extension appropriate to the current platform is present'
  task :build_mri => ["ext/blockenspiel/#{unmixer_name_}"] do
    cp "ext/blockenspiel/#{unmixer_name_}", "lib/blockenspiel/#{unmixer_general_name_}"
  end
  
  file "ext/blockenspiel/#{unmixer_name_}" => ["ext/blockenspiel/#{makefile_name_}"] do
    ::Dir.chdir('ext/blockenspiel') do
      cp makefile_name_, 'Makefile'
      sh 'make'
      rm 'unmixer_mri.o'
      mv unmixer_general_name_, unmixer_name_
    end
  end
  
  file "ext/blockenspiel/#{makefile_name_}" do
    ::Dir.chdir('ext/blockenspiel') do
      ruby 'extconf.rb'
      mv 'Makefile', makefile_name_
    end  
  end
  
end


# Build tasks for JRuby.
# These are available under any ruby.
# They assume that $JRUBY_HOME is set, and that the javac and jar
# binaries are in the current path.

desc 'Builds the JRuby extension'
task :build_jruby => ['lib/blockenspiel_unmixer_jruby.jar']

file 'lib/blockenspiel_unmixer_jruby.jar' do
  ::Dir.chdir('ext/blockenspiel') do
    sh 'javac -source 1.5 -target 1.5 -classpath $JRUBY_HOME/lib/jruby.jar BlockenspielUnmixerJrubyService.java'
    sh 'jar cf blockenspiel_unmixer_jruby.jar BlockenspielUnmixerJrubyService.class'
  end
  mv 'ext/blockenspiel/blockenspiel_unmixer_jruby.jar', 'lib'
end


# Publish RDocs

desc 'Publishes RDocs to RubyForge'
task :publish_rdoc_to_rubyforge => [:rerdoc] do
  config_ = ::YAML.load(::File.read(::File.expand_path("~/.rubyforge/user-config.yml")))
  username_ = config_['username']
  sh "rsync -av --delete doc/ #{username_}@rubyforge.org:/var/www/gforge-projects/virtuoso/blockenspiel"
end


# Publish gem

task :release_gem => [:package] do |t_|
  v_ = ::ENV["VERSION"]
  abort "Must supply VERSION=x.y.z" unless v_
  if v_ != ::Blockenspiel::VERSION_STRING
    abort "Versions don't match: #{v_} vs #{::Blockenspiel::VERSION_STRING}"
  end
  puts "Releasing blockenspiel #{v_}"
  ::Dir.chdir('pkg') do
    sh "gem push blockenspiel-#{v_}.gem"
    sh "gem push blockenspiel-#{v_}-java.gem"
  end
end


# Publish everything

task :release => [:release_gem, :publish_rdoc_to_rubyforge]


# Custom task that takes the implementing dsl blocks paper
# and converts it from RDoc format to Markdown

task :idslb_markdown do
  ::File.open('ImplementingDSLblocks.rdoc') do |read_|
    ::File.open('idslb_markdown.txt', 'w') do |write_|
      linenum_ = 0
      read_.each do |line_|
        linenum_ += 1
        next if linenum_ < 4
        line_.sub!(/^===\ /, '### ')
        line_.sub!(/^\ \ /, '    ')
        if line_[0..3] == '### '
          line_.gsub!(/(\w)_(\w)/, '\1\_\2')
        end
        if line_[0..3] != '    '
          line_.gsub!('"it_should_behave_like"', '"it\_should\_behave\_like"')
          line_.gsub!('"time_zone"', '"time\_zone"')
          line_.gsub!(/\+(\w+)\+/, '`\1`')
          line_.gsub!(/\*(\w+)\*/, '**\1**')
          line_.gsub!(/<\/?em>/, '*')
          line_.gsub!(/<\/?tt>/, '`')
          line_.gsub!(/<\/?b>/, '**')
          line_.gsub!(/\{([^\}]+)\}\[([^\]]+)\]/) do |match_|
            text_, url_ = $1, $2
            "[#{text_.gsub('_', '\_')}](#{url_})"
          end
          line_.gsub!(/\ (http:\/\/[^\s]+)/, ' [\1](\1)')
        end
        write_.puts(line_)
      end
    end
  end
end
