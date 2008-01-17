module ActiveCouch
  
  String.class_eval do
    require 'cgi'
    def url_encode
      CGI.escape("\"#{self.to_s}\"")
    end
  end
  
  Hash.class_eval do
    # Flatten on the array removes everything into *one* single array,
    # so {}.to_a.flatten sometimes won't work nicely because a value might be an array
    # So..introducing flatten for Hash, so that arrays which are values (to keys)
    # are retained
    def flatten
      (0...self.size).inject([]) {|k,v| k << self.keys[v]; k << self.values[v]}
    end 
  end

  Object.class_eval do
    def get_class(name)
      # From 'The Ruby Way Second Edition' by Hal Fulton
      # This is to get nested class for e.g. A::B::C
      name.split("::").inject(Object) {|x,y| x.const_get(y)}
    end

    # The singleton class.
    def metaclass; class << self; self; end; end
    def meta_eval &blk; metaclass.instance_eval &blk; end

    # Adds methods to a metaclass.
    def meta_def name, &blk
      meta_eval { define_method name, &blk }
    end

    # Defines an instance method within a class.
    def class_def name, &blk
      class_eval { define_method name, &blk }
    end
  end
  
  Module.module_eval do
    # Return the module which contains this one; if this is a root module, such as
    # +::MyModule+, then Object is returned.
    def parent
      parent_name = name.split('::')[0..-2] * '::'
      parent_name.empty? ? Object : Inflector.constantize(parent_name)
    end
  end
end