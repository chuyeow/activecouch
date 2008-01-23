module ActiveCouch
  class Attribute
    attr_reader :name, :klass, :value
    TYPES = {:decimal => Float, :text => String, :number => Integer}
    DEFAULTS = {:decimal => 0.0, :text => "", :number => 0}
    
    def initialize(name, options = {})
      klass, value = String, ""
      # Check for types supported
      if options.has_key?(:which_is)
        type = options[:which_is]
        unless type == :decimal || type == :number || type == :text
          raise InvalidCouchTypeError, "Types must be either decimal, number or text"
        else
          klass = TYPES[type]; value = DEFAULTS[type]
        end
      end
      # Check if default value provided matches the type provided
      if options.has_key?(:with_default_value)
        value = options[:with_default_value]
        unless value.is_a?(klass) || value.is_a?(NilClass)
          raise InvalidCouchTypeError, "Default value provided does not match the type of #{klass.to_s}"
        end
      end
      # Set the value, defaults to empty String
      @value, @klass, @name = value, klass, name.to_s
    end
    
    def value=(val)
      unless val.is_a?(@klass) || val.is_a?(NilClass)
        raise InvalidCouchTypeError, "Default value provided does not match the type of #{@klass.to_s}"
      end
      # Set the value if value matches type
      @value = val
    end
    
    def to_hash
      { @name => @value }
    end
    
    def nil?
      @value.nil?
    end
    
  end # End class CouchAttribute  
end # End module ActiveCouch
