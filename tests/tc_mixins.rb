# -----------------------------------------------------------------------------
# 
# Blockenspiel mixin tests
# 
# This file contains tests for various mixin cases,
# including nested blocks and multithreading.
# 
# -----------------------------------------------------------------------------
# Copyright 2008 Daniel Azuma
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


require File.expand_path("#{File.dirname(__FILE__)}/../lib/blockenspiel.rb")


module Blockenspiel
  module Tests  # :nodoc:
    
    class TestMixins < Test::Unit::TestCase  # :nodoc:
      
      
      class Target1 < Blockenspiel::Base
        
        def initialize(hash_)
          @hash = hash_
        end
        
        def set_value(key_, value_)
          @hash["#{key_}1"] = value_
        end
        
        def set_value2(key_)
          @hash["#{key_}1"] = yield
        end
        
      end
      
      
      class Target2 < Blockenspiel::Base
        
        dsl_methods false
        
        def initialize(hash_=nil)
          @hash = hash_ || Hash.new
        end
        
        def set_value(key_, value_)
          @hash["#{key_}2"] = value_
        end
        dsl_method :set_value
        
        def set_value2(key_)
          @hash["#{key_}2"] = yield
        end
        dsl_method :set_value2_inmixin, :set_value2
        
      end
      
      
      # Basic test of mixin mechanism.
      # 
      # * Asserts that the mixin methods are added and removed for a single mixin.
      # * Asserts that the methods properly delegate to the target object.
      # * Asserts that self doesn't change, and instance variables are preserved.
      
      def test_basic_mixin
        hash_ = Hash.new
        saved_object_id_ = self.object_id
        @my_instance_variable_test = :hello
        assert(!self.respond_to?(:set_value))
        assert(!self.respond_to?(:set_value2))
        Blockenspiel.invoke(proc do
          set_value('a', 1)
          set_value2('b'){ 2 }
          assert_equal(:hello, @my_instance_variable_test)
          assert_equal(saved_object_id_, self.object_id)
        end, Target1.new(hash_))
        assert(!self.respond_to?(:set_value))
        assert(!self.respond_to?(:set_value2))
        assert_equal(1, hash_['a1'])
        assert_equal(2, hash_['b1'])
      end
      
      
      # Test renaming of mixin methods.
      # 
      # * Asserts that correctly renamed mixin methods are added and removed.
      # * Asserts that the methods properly delegate to the target object.
      
      def test_mixin_with_renaming
        hash_ = Hash.new
        assert(!self.respond_to?(:set_value))
        assert(!self.respond_to?(:set_value2))
        assert(!self.respond_to?(:set_value2_inmixin))
        Blockenspiel.invoke(proc do
          set_value('a', 1)
          set_value2_inmixin('b'){ 2 }
          assert(!self.respond_to?(:set_value2))
        end, Target2.new(hash_))
        assert(!self.respond_to?(:set_value))
        assert(!self.respond_to?(:set_value2))
        assert(!self.respond_to?(:set_value2_inmixin))
        assert_equal(1, hash_['a2'])
        assert_equal(2, hash_['b2'])
      end
      
      
      # Test of two different nested mixins.
      # 
      # * Asserts that the right methods are added and removed at the right time.
      # * Asserts that the methods delegate to the right target object, even when
      #   multiple mixins add the same method name
      
      def test_nested_different
        hash_ = Hash.new
        assert(!self.respond_to?(:set_value))
        assert(!self.respond_to?(:set_value2))
        assert(!self.respond_to?(:set_value2_inmixin))
        Blockenspiel.invoke(proc do
          set_value('a', 1)
          set_value2('b'){ 2 }
          assert(!self.respond_to?(:set_value2_inmixin))
          Blockenspiel.invoke(proc do
            set_value('c', 1)
            set_value2_inmixin('d'){ 2 }
          end, Target2.new(hash_))
          assert(!self.respond_to?(:set_value2_inmixin))
          set_value('e', 1)
          set_value2('f'){ 2 }
        end, Target1.new(hash_))
        assert(!self.respond_to?(:set_value))
        assert(!self.respond_to?(:set_value2))
        assert(!self.respond_to?(:set_value2_inmixin))
        assert_equal(1, hash_['a1'])
        assert_equal(2, hash_['b1'])
        assert_equal(1, hash_['c2'])
        assert_equal(2, hash_['d2'])
        assert_equal(1, hash_['e1'])
        assert_equal(2, hash_['f1'])
      end
      
      
      # Test of the same mixin nested in itself.
      # 
      # * Asserts that the methods are added and removed at the right time.
      
      def test_nested_same
        hash_ = Hash.new
        assert(!self.respond_to?(:set_value))
        assert(!self.respond_to?(:set_value2))
        assert(!self.respond_to?(:set_value2_inmixin))
        Blockenspiel.invoke(proc do
          set_value('a', 1)
          set_value2_inmixin('b'){ 2 }
          Blockenspiel.invoke(proc do
            set_value('c', 1)
            set_value2_inmixin('d'){ 2 }
            assert(!self.respond_to?(:set_value2))
          end, Target2.new(hash_))
          set_value('e', 1)
          set_value2_inmixin('f'){ 2 }
        end, Target2.new(hash_))
        assert(!self.respond_to?(:set_value))
        assert(!self.respond_to?(:set_value2))
        assert(!self.respond_to?(:set_value2_inmixin))
        assert_equal(1, hash_['a2'])
        assert_equal(2, hash_['b2'])
        assert_equal(1, hash_['c2'])
        assert_equal(2, hash_['d2'])
        assert_equal(1, hash_['e2'])
        assert_equal(2, hash_['f2'])
      end
      
      
    end
    
  end
end
