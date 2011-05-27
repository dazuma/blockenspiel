# -----------------------------------------------------------------------------
# 
# Blockenspiel unmixer for Rubinius
# 
# -----------------------------------------------------------------------------
# Copyright 2010 Daniel Azuma
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


module Blockenspiel
  
  
  # :stopdoc:
  
  module Unmixer
    
    
    # Unmix a module from an object in Rubinius.
    # 
    # This implementation is based on unreleased code from the Mixology
    # source, written by Dan Manges.
    # See http://github.com/dan-manges/mixology
    # 
    # It has been stripped down and modified for compatibility with the
    # Rubinius 1.0 release.
    
    def self.unmix(obj_, mod_)  # :nodoc:
      last_super_ = obj_.singleton_class
      this_super_ = last_super_.direct_superclass
      while this_super_
        if (this_super_ == mod_ || this_super_.respond_to?(:module) && this_super_.module == mod_)
          _reset_method_cache(obj_)
          last_super_.superclass = this_super_.direct_superclass
          _reset_method_cache(obj_)
          return
        else
          last_super_ = this_super_
          this_super_ = this_super_.direct_superclass
        end
      end
      nil
    end
    
    
    def self._reset_method_cache(obj_)  # :nodoc:
      obj_.methods.each do |name_|
        ::Rubinius::VM.reset_method_cache(name_.to_sym)
      end
    end
    
    
  end
  
  # :startdoc:
  
  
end
