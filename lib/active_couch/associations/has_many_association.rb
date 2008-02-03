# TODO Consider implementing Enumerable semantics.

module ActiveCouch
  class HasManyAssociation
    attr_accessor :name, :klass, :container
    
    def initialize(name, options = {})
      @name, @container, klass = name.to_s, [], options[:class]
      if !klass.nil? && klass.is_a?(Class)
        @klass = klass
      else
        # Use the inflector to get the correct class if it is not defined 
        # in the :class key in the options hash
        # so has_many :contacts (will try to find the class Contact and set it to @klass)
        @klass = @name.classify.constantize #Inflector.constantize(Inflector.classify(@name))
      end
    end

    def push(obj)
      unless obj.is_a?(klass)
        raise InvalidCouchTypeError, "The object that you are trying to add is not a #{klass}"
      end
      @container << obj
    end
    
    def pop
      @container.pop
    end
    
    def to_hash
      { @name => @container }
    end
    
  end
end