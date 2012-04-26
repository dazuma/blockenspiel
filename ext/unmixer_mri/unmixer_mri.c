/*
  -----------------------------------------------------------------------------

  Blockenspiel unmixer (MRI implementation)

  -----------------------------------------------------------------------------
  Copyright 2008-2011 Daniel Azuma

  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  * Neither the name of the copyright holder, nor the names of any other
    contributors to this software, may be used to endorse or promote products
    derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
  -----------------------------------------------------------------------------
*/


/*
  This implementation based on Mixology 0.1,
  written by Patrick Farley, anonymous z, Dan Manges, and Clint Bishop.
  http://rubyforge.org/projects/mixology
  http://github.com/dan-manges/mixology/tree/master

  It has been stripped down and modified for compatibility with Ruby 1.9.

  Note that this C extension is specific to MRI.
*/


#include <ruby.h>

/* Support for ruby >= 1.9.3 that deprecates RCLASS_SUPER */
#ifdef HAVE_RUBY_BACKWARD_CLASSEXT_H
#include <ruby/backward/classext.h>
#endif

/* Support for pre-1.9 rubies that don't provide RCLASS_SUPER */
#ifndef RCLASS_SUPER
#define RCLASS_SUPER(c) (RCLASS(c)->super)
#endif


#ifndef RUBINIUS


static void remove_nested_module(VALUE klass, VALUE module) {
  if (CLASS_OF(RCLASS_SUPER(klass)) == CLASS_OF(RCLASS_SUPER(module))) {
    if (RCLASS_SUPER(RCLASS_SUPER(module)) && BUILTIN_TYPE(RCLASS_SUPER(module)) == T_ICLASS) {
      remove_nested_module(RCLASS_SUPER(klass), RCLASS_SUPER(module));
    }
    RCLASS_SUPER(klass) = RCLASS_SUPER(RCLASS_SUPER(klass));
  }
}


static VALUE do_unmix(VALUE self, VALUE receiver, VALUE module) {
  VALUE klass = CLASS_OF(receiver);
  while (klass != rb_class_real(klass)) {
    VALUE super = RCLASS_SUPER(klass);
    if (BUILTIN_TYPE(super) == T_ICLASS && CLASS_OF(super) == module) {
      if (RCLASS_SUPER(module) && BUILTIN_TYPE(RCLASS_SUPER(module)) == T_ICLASS) {
        remove_nested_module(super, module);
      }
      RCLASS_SUPER(klass) = RCLASS_SUPER(super);
      rb_clear_cache();
    }
    klass = super;
  }
  return receiver;
}


#endif


void Init_unmixer_mri() {
#ifndef RUBINIUS

  VALUE container = rb_singleton_class(rb_define_module_under(rb_define_module("Blockenspiel"), "Unmixer"));
  rb_define_method(container, "unmix", do_unmix, 2);

#endif
}
