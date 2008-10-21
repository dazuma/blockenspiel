# -----------------------------------------------------------------------------
# 
# Blockenspiel implementation
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
;


require 'rubygems'
require 'mixology'


# == Blockenspiel
# 
# The Blockenspiel module provides a namespace for Blockenspiel, as well as
# the main entry point method "invoke".

module Blockenspiel
  
  # Current gem version
  VERSION_STRING = '0.1.0'
  
  
  # === DSL setup methods
  # 
  # These class methods are available after you have included the
  # Blockenspiel::DSL module.
  # 
  # By default, a class that has DSL capability will automatically make
  # all public methods available to parameterless blocks, except for the
  # +initialize+ method, any methods whose names begin with an underscore,
  # and any methods whose names end with an equals sign.
  # 
  # If you want to change this behavior, use the directives defined here to
  # control exactly which methods are available to parameterless blocks.
  
  module DSLSetupMethods
    
    # Called when DSLSetupMethods extends a class.
    # This sets up the current class, and adds a hook that causes
    # any subclass of the current class to also be set up.
    
    def self.extended(klass_)  # :nodoc:
      unless klass_.instance_variable_defined?(:@_blockenspiel_module)
        _setup_class(klass_)
        def klass_.inherited(subklass_)
          Blockenspiel::DSLSetupMethods._setup_class(subklass_)
          super
        end
      end
    end
    
    
    # Set up a class.
    # Creates a DSL module for this class, optionally delegating to the superclass's module.
    # Also initializes the class's methods hash and active flag.
    
    def self._setup_class(klass_)  # :nodoc:
      superclass_ = klass_.superclass
      superclass_ = nil unless superclass_.respond_to?(:_get_blockenspiel_module)
      mod_ = Module.new
      if superclass_
        mod_.module_eval do
          include superclass_._get_blockenspiel_module
        end
      end
      klass_.instance_variable_set(:@_blockenspiel_superclass, superclass_)
      klass_.instance_variable_set(:@_blockenspiel_module, mod_)
      klass_.instance_variable_set(:@_blockenspiel_methods, Hash.new)
      klass_.instance_variable_set(:@_blockenspiel_active, nil)
    end
    
    
    # Hook called when a method is added.
    # This automatically makes the method a DSL method according to the current setting.
    
    def method_added(symbol_)  # :nodoc:
      if @_blockenspiel_active
        dsl_method(symbol_)
      elsif @_blockenspiel_active.nil?
        if symbol_ != :initialize && symbol_.to_s !~ /^_/ && symbol_.to_s !~ /=$/
          dsl_method(symbol_)
        end
      end
      super
    end
    
    
    # Get this class's corresponding DSL module
    
    def _get_blockenspiel_module  # :nodoc:
      @_blockenspiel_module
    end
    
    
    # Get information on the given DSL method name.
    # Possible values are the name of the delegate method, false for method disabled,
    # or nil for method never defined.
    
    def _get_blockenspiel_delegate(name_)  # :nodoc:
      delegate_ = @_blockenspiel_methods[name_]
      if delegate_.nil? && @_blockenspiel_superclass
        @_blockenspiel_superclass._get_blockenspiel_delegate(name_)
      else
        delegate_
      end
    end
    
    
    # Make a particular method available to parameterless DSL blocks.
    # 
    # To explicitly make a method available to parameterless blocks:
    #  dsl_method :my_method
    # 
    # To explicitly exclude a method from parameterless blocks:
    #  dsl_method :my_method, false
    # 
    # To explicitly make a method available to parameterless blocks, but
    # point it to a method of a different name on the target class:
    #  dsl_method :my_method, :target_class_method
    
    def dsl_method(name_, delegate_=nil)
      name_ = name_.to_sym
      if delegate_
        delegate_ = delegate_.to_sym
      elsif delegate_.nil?
        delegate_ = name_
      end
      @_blockenspiel_methods[name_] = delegate_
      unless @_blockenspiel_module.public_method_defined?(name_)
        @_blockenspiel_module.module_eval("
          def #{name_}(*params_, &block_)
            val_ = Blockenspiel._delegate(:#{name_}, params_, block_)
            val_ == Blockenspiel::TARGET_MISMATCH ? super(*params_, &block_) : val_
          end
        ")
      end
    end
    
    
    # Control the behavior of methods with respect to parameterless blocks,
    # or make a list of methods available to parameterless blocks in bulk.
    # 
    # To enable automatic exporting of methods to parameterless blocks.
    # After executing this command, all public methods defined in the class
    # will be available on parameterless blocks, until
    # <tt>dsl_methods false</tt> is called.
    #  dsl_methods true
    # 
    # To disable automatic exporting of methods to parameterless blocks.
    # After executing this command, methods defined in this class will be
    # excluded from parameterless blocks, until <tt>dsl_methods true</tt>
    # is called.
    #  dsl_methods false
    # 
    # To make a list of methods available to parameterless blocks in bulk:
    #  dsl_methods :my_method1, :my_method2, ...
    
    def dsl_methods(*names_)
      if names_.size == 0 || names_ == [true]
        @_blockenspiel_active = true
      elsif names_ == [false]
        @_blockenspiel_active = false
      else
        if names_.last.kind_of?(Hash)
          names_.pop.each do |name_, delegate_|
            dsl_method(name_, delegate_)
          end
        end
        names_.each do |name_|
          dsl_method(name_, name_)
        end
      end
    end
    
  end
  
  
  # === DSL activation module
  # 
  # Include this module in a class to mark this class as a DSL class and
  # make it possible for its methods to be called from a block that does not
  # take a parameter.
  # 
  # After you include this module, you can use the directives defined in
  # DSLSetupMethods to control what methods are available to DSL blocks
  # that do not take parameters.
  
  module DSL
    
    def self.included(klass_)  # :nodoc:
      klass_.extend(Blockenspiel::DSLSetupMethods)
    end
    
  end
  
  
  # === DSL activation base class
  # 
  # Subclasses of this base class are considered DSL classes.
  # Methods of the class can be made available to be called from a block that
  # doesn't take an explicit block parameter.
  # You may use the directives defined in DSLSetupMethods to control how
  # methods of the class are handled in such blocks.
  # 
  # Subclassing this base class is functionally equivalent to simply
  # including Blockenspiel::DSL in the class.
  
  class Base
    
    include Blockenspiel::DSL
    
  end
  
  
  # === Dynamically construct a target
  # 
  # These methods are available in a block passed to Blockenspiel#invoke and
  # can be used to dynamically define what methods are available from a block.
  # See Blockenspiel#invoke for more information.
  
  class Builder
    
    include Blockenspiel::DSL
    
    
    # This is a base class for dynamically constructed targets.
    # The actual target class is an anonymous subclass of this base class.
    
    class Target  # :nodoc:
      
      include Blockenspiel::DSL
      
      
      # Add a method specification to the subclass.
      
      def self._add_methodinfo(name_, block_, yields_)
        (@_blockenspiel_methodinfo ||= Hash.new)[name_] = [block_, yields_]
        module_eval("
          def #{name_}(*params_, &block_)
            self.class._invoke_methodinfo(:#{name_}, params_, block_)
          end
        ")
      end
      
      
      # Attempt to invoke the given method on the subclass.
      
      def self._invoke_methodinfo(name_, params_, block_)
        info_ = @_blockenspiel_methodinfo[name_]
        if info_[1]
          realparams_ = params_ + [block_]
          info_[0].call(*realparams_)
        else
          info_[0].call(*params_)
        end
      end
      
    end
    
    
    # Sets up the dynamic target class.
    
    def initialize  # :nodoc:
      @target_class = Class.new(Blockenspiel::Builder::Target)
      @target_class.dsl_methods(false)
    end
    
    
    # Creates a new instance of the dynamic target class
    
    def _create_target  # :nodoc:
      @target_class.new
    end
    
    
    # Make a method available within the block.
    # 
    # Provide a name for the method, and a block defining the method's
    # implementation.
    # 
    # By default, a method of the same name is also made available in
    # mixin mode. To change the name of the mixin method, set its name
    # as the value of the <tt>:mixin</tt> parameter. To disable the
    # mixin method, set the <tt>:mixin</tt> parameter to +false+.
    
    def add_method(name_, opts_={}, &block_)
      @target_class._add_methodinfo(name_, block_, opts_[:receive_block])
      mixin_name_ = opts_[:mixin]
      if mixin_name_ != false
        mixin_name_ = name_ if mixin_name_.nil? || mixin_name_ == true
        @target_class.dsl_method(mixin_name_, name_)
      end
    end
    
  end
  
  
  # :stopdoc:
  TARGET_MISMATCH = Object.new
  # :startdoc:
  
  @_target_stacks = Hash.new
  @_mixin_counts = Hash.new
  @_mutex = Mutex.new
  
  
  # === Invoke a given block.
  # 
  # This is the meat of Blockenspiel. Call this function to invoke a block
  # provided by the user of your API.
  # 
  # Normally, this method will check the block's arity to see whether it
  # takes a parameter. If so, it will pass the given target to the block.
  # If the block takes no parameter, and the given target is an instance of
  # a class with DSL capability, the DSL methods are made available on the
  # caller's self object so they may be called without a block parameter.
  # 
  # Recognized options include:
  # 
  # <tt>:parameterless</tt>::
  #   If set to false, disables parameterless blocks and always attempts to
  #   pass a parameter to the block. Otherwise, you may set it to one of
  #   three behaviors for parameterless blocks: <tt>:mixin</tt> (the
  #   default), <tt>:mixin_inheriting</tt>, and <tt>:instance</tt>. See
  #   below for a description of these behaviors.
  # <tt>:parameter</tt>::
  #   If set to false, disables blocks with parameters, and always attempts
  #   to use parameterless blocks. Default is true, enabling parameter mode.
  # 
  # The following values control the precise behavior of parameterless
  # blocks. These are values for the <tt>:parameterless</tt> option.
  # 
  # <tt>:mixin</tt>::
  #   This is the default behavior. DSL methods from the target are
  #   temporarily overlayed on the caller's self object, but self is itself
  #   not modified, so the helper methods and instance variables from the
  #   caller's closure remain available. The DSL methods are removed when
  #   the block completes.
  # <tt>:mixin_inheriting</tt>::
  #   This behavior is the same as mixin, with an additional feature when
  #   DSL blocks are nested. Under normal mixin, only the current block's
  #   DSL methods are available; any outer blocks have their methods
  #   disabled. If you use mixin_inheriting, and a method is not implemented
  #   in the current block, then the next outer block is given a chance to
  #   handle it-- that is, this block "inherits" methods from any block it
  #   is nested within.
  # <tt>:instance</tt>::
  #   This behavior actually changes +self+ to the target object using
  #   <tt>instance_eval</tt>. Thus, the caller loses access to its own
  #   helper methods and instance variables, and instead gains access to the
  #   target object's instance variables.
  # 
  # === Dynamic target generation
  # 
  # It is also possible to dynamically generate a target object by passing
  # a block to this method. This is probably best illustrated by example:
  # 
  #  Blockenspiel.invoke(block) do
  #    add_method(:set_foo) do |value|
  #      my_foo = value
  #    end
  #    add_method(:set_things_from_block, :receive_block => true) do |value,blk|
  #      my_foo = value
  #      my_bar = blk.call
  #    end
  #  end
  # 
  # The above is roughly equivalent to invoking Blockenspiel with an
  # instance of this target class:
  # 
  #  class MyFooTarget
  #    include Blockenspiel::DSL
  #    def set_foo(value)
  #      set_my_foo_from(value)
  #    end
  #    def set_things_from_block(value)
  #      set_my_foo_from(value)
  #      set_my_bar_from(yield)
  #    end
  #  end
  #  
  #  Blockenspiel.invoke(block, MyFooTarget.new)
  # 
  # The obvious advantage of using dynamic object generation is that you are
  # creating methods using closures, which provides the opportunity to, for
  # example, modify closure variables such as my_foo. This is more difficult
  # to do when you create a target class since its methods do not have access
  # to outside data. Hence, in the above example, we hand-waved, assuming the
  # existence of some method called "set_my_foo_from".
  # 
  # The disadvantage is performance. If you dynamically generate a target
  # object, it involves parsing and creating a new class whenever it is
  # invoked. Thus, it is recommended that you use this technique for calls
  # that are not used repeatedly, such as one-time configuration.
  # 
  # See the Blockenspiel::Builder class for more details on add_method.
  # 
  # (And yes, you guessed it: this API is a DSL block, and is itself
  # implemented using Blockenspiel.)
  
  def self.invoke(block_, target_=nil, opts_={}, &builder_block_)
    
    # Handle this case gracefully
    return nil unless block_
    
    # Handle dynamic target generation
    if builder_block_
      opts_ = target_ || opts_
      builder_ = Blockenspiel::Builder.new
      invoke(builder_block_, builder_)
      target_ = builder_._create_target
    end
    
    # Attempt parameterless block
    parameterless_ = opts_[:parameterless]
    if parameterless_ != false && (block_.arity == 0 || block_.arity == -1)
      if parameterless_ == :instance
        
        # Instance-eval behavior.
        # Note: this does not honor DSL method renaming, etc.
        # Not sure how best to handle those cases, since we cannot
        # overlay the module on its own target.
        return target_.instance_eval(&block_)
        
      else
        
        # Mixin behavior
        mod_ = target_.class._get_blockenspiel_module rescue nil
        if mod_
          
          # Get the thread and self context
          thread_id_ = Thread.current.object_id
          object_ = Kernel.eval('self', block_.binding)
          object_id_ = object_.object_id
          
          # Store the target for inheriting.
          # We maintain a target call stack per thread.
          target_stack_ = @_target_stacks[thread_id_] ||= Array.new
          target_stack_.push([target_, parameterless_ == :mixin_inheriting])
          
          # Mix this module into the object, if required.
          # This ensures that we keep track of the number of requests to
          # mix this module in, from nested blocks and possibly multiple threads.
          @_mutex.synchronize do
            count_ = @_mixin_counts[[object_id_, mod_]]
            if count_
              @_mixin_counts[[object_id_, mod_]] = count_ + 1
            else
              @_mixin_counts[[object_id_, mod_]] = 1
              object_.mixin(mod_)
            end
          end
          
          begin
            
            # Now call the block
            return block_.call
            
          ensure
            
            # Clean up the target stack
            target_stack_.pop
            @_target_stacks.delete(thread_id_) if target_stack_.size == 0
            
            # Remove the mixin from the object, if required.
            @_mutex.synchronize do
              count_ = @_mixin_counts[[object_id_, mod_]]
              if count_ == 1
                @_mixin_counts.delete([object_id_, mod_])
                object_.unmix(mod_)
              else
                @_mixin_counts[[object_id_, mod_]] = count_ - 1
              end
            end
            
          end
          
        end
        # End mixin behavior
        
      end
    end
    
    # Attempt parametered block
    if opts_[:parameter] != false && block_.arity != 0
      return block_.call(target_)
    end
    
    # Last resort fall-back
    return block_.call
    
  end
  
  
  # This implements the mapping between DSL module methods and target object methods.
  # We look up the current target object based on the current thread.
  # Then we attempt to call the given method on that object.
  # If we can't find an appropriate method to call, return the special value TARGET_MISMATCH.
  
  def self._delegate(name_, params_, block_)  # :nodoc:
    target_stack_ = @_target_stacks[Thread.current.object_id]
    return TARGET_MISMATCH unless target_stack_
    target_stack_.reverse_each do |elem_|
      target_ = elem_[0]
      target_class_ = target_.class
      delegate_ = target_class_._get_blockenspiel_delegate(name_)
      if delegate_ && target_class_.public_method_defined?(delegate_)
        return target_.send(delegate_, *params_, &block_)
      end
      return TARGET_MISMATCH unless elem_[1]
    end
    return TARGET_MISMATCH
  end
  
  
end
