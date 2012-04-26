# -----------------------------------------------------------------------------
#
# Blockenspiel Rakefile configuration
#
# -----------------------------------------------------------------------------
# Copyright 2012 Daniel Azuma
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


task :build_other => ['lib/blockenspiel_unmixer_jruby.jar']
file 'lib/blockenspiel_unmixer_jruby.jar' do
  if `ruby --version` =~ /jruby/
    ::Dir.chdir('java') do
      sh 'javac -source 1.5 -target 1.5 -classpath $MY_RUBY_HOME/lib/jruby.jar BlockenspielUnmixerJrubyService.java'
      sh 'jar cf blockenspiel_unmixer_jruby.jar BlockenspielUnmixerJrubyService.class'
      rm 'BlockenspielUnmixerJrubyService.class'
    end
    mv 'java/blockenspiel_unmixer_jruby.jar', 'lib'
  end
end


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
