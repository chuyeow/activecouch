module ActiveCouch

  Symbol.class_eval do
    def singularize; ActiveCouch::Inflector.singularize(self); end
  end

  String.class_eval do
    require 'cgi'
    def url_encode; CGI.escape("\"#{self.to_s}\""); end
    # Delegate to Inflector
    def singularize; ActiveCouch::Inflector.singularize(self); end
    def demodulize; ActiveCouch::Inflector.demodulize(self); end
    def pluralize; ActiveCouch::Inflector.pluralize(self); end
    def underscore; ActiveCouch::Inflector.underscore(self); end
    def classify; ActiveCouch::Inflector.classify(self); end
    def constantize; ActiveCouch::Inflector.constantize(self); end
  end

  Array.class_eval do
    def extract_options!
      last.is_a?(::Hash) ? pop : {}
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
      parent_name.empty? ? Object : ActiveCouch::Inflector.constantize(parent_name)
    end
    
    def alias_method_chain(target, feature)
      # Strip out punctuation on predicates or bang methods since
      # e.g. target?_without_feature is not a valid method name.
      aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
      yield(aliased_target, punctuation) if block_given?

      with_method, without_method = "#{aliased_target}_with_#{feature}#{punctuation}", "#{aliased_target}_without_#{feature}#{punctuation}"

      alias_method without_method, target
      alias_method target, with_method

      case
        when public_method_defined?(without_method)
          public target
        when protected_method_defined?(without_method)
          protected target
        when private_method_defined?(without_method)
          private target
      end
    end
  end
end