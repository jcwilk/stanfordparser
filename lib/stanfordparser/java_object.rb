# Copyright 2007-2008 William Patrick McNeill
#
# This file is part of the Stanford Parser Ruby Wrapper.
#
# The Stanford Parser Ruby Wrapper is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the License,
# or (at your option) any later version.
#
# The Stanford Parser Ruby Wrapper is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# editalign; if not, write to the Free Software Foundation, Inc., 51 Franklin
# St, Fifth Floor, Boston, MA 02110-1301 USA

# Extenions to the {Ruby-Java Bridge}[http://rjb.rubyforge.org/] module that
# add a generic Java object wrapper class.
module Rjb

  #--
  # The documentation for this class appears next to its extension inside the
  # StanfordParser module in stanfordparser.rb.  This should be changed if Rjb
  # is ever moved into its own gem.  See the documention in stanfordparser.rb
  # for more details.  
  #++
  class JavaObjectWrapper
    include Enumerable

    # The underlying Java object.
    attr_reader :java_object

    # Initialize with a Java object <em>obj</em>.  If <em>obj</em> is a
    # String, treat it as a Java class name and instantiate it.  Otherwise,
    # treat <em>obj</em> as an instance of a Java object.
    def initialize(obj, *args)
      @java_object = obj.class == String ?
      Rjb::import(obj).send(:new, *args) : obj
    end

    # Enumerate all the items in the object using its iterator.  If the object
    # has no iterator, this function yields nothing.
    def each
      if @java_object.getClass.getMethods.any? {|m| m.getName == "iterator"}
        i = @java_object.iterator
        while i.hasNext
          yield wrap_java_object(i.next)
        end
      end
    end # each

    # Reflect unhandled method calls to the underlying Java object and wrap
    # the return value in the appropriate Ruby object.
    def method_missing(m, *args)
      begin
        wrap_java_object(@java_object.send(m, *args))
      rescue RuntimeError => e
        # The instance method failed.  See if this is a static method.
        if not e.message.match(/^Fail: unknown method name/).nil?
          getClass.send(m, *args)
        end
      end
    end

    # Convert a value returned by a call to the underlying Java object to the
    # appropriate Ruby object.
    #
    # If the value is a JavaObjectWrapper, convert it using a protected
    # function with the name wrap_ followed by the underlying object's
    # classname with the Java path delimiters converted to underscores. For
    # example, a <tt>java.util.ArrayList</tt> would be converted by a function
    # called wrap_java_util_ArrayList.
    #
    # If the value lacks the appropriate converter function, wrap it in a
    # generic JavaObjectWrapper.
    #
    # If the value is not a JavaObjectWrapper, return it unchanged.
    #
    # This function is called recursively for every element in an Array.
    def wrap_java_object(object)
      if object.kind_of?(Array)
        object.collect {|item| wrap_java_object(item)}
      elsif object.respond_to?(:_classname)
        # Ruby-Java Bridge Java objects all have a _classname member which
        # tells the name of their Java class.  Convert this to the
        # corresponding wrapper function name.
        wrapper_name = ("wrap_" + object._classname.gsub(/\./, "_")).to_sym
        respond_to?(wrapper_name) ? send(wrapper_name, object) : JavaObjectWrapper.new(object)
      else
        object
      end
    end

    # Convert <tt>java.util.ArrayList</tt> objects to Ruby Array objects.
    def wrap_java_util_ArrayList(object)
      array_list = []
      object.size.times do
        |i| array_list << wrap_java_object(object.get(i))
      end
      array_list
    end

    # Convert <tt>java.util.HashSet</tt> objects to Ruby Set objects.
    def wrap_java_util_HashSet(object)
      set = Set.new
      i = object.iterator
      while i.hasNext
        set << wrap_java_object(i.next)
      end
      set
    end

    # Show the classname of the underlying Java object.
    def inspect
      "<#{@java_object._classname}>"
    end

    # Use the underlying Java object's stringification.
    def to_s
      toString
    end

    protected :wrap_java_object, :wrap_java_util_ArrayList, :wrap_java_util_HashSet

  end # JavaObjectWrapper

end # Rjb
