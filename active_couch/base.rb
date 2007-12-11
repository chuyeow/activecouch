module ActiveCouch
  class Base
    def initialize
      # Object instance variable
      @attributes, @associations, klass_atts, klass_assocs = {}, {}, self.class.attributes, self.class.associations
      
      self.instance_eval "def attributes; @attributes; end"
      self.instance_eval "def associations; @associations; end"
      
      klass_atts.each_key do |k|
        @attributes[k] = klass_atts[k].clone
        self.instance_eval "def #{k}; attributes[:#{k}].value; end"
        self.instance_eval "def #{k}=(val); attributes[:#{k}].value = val; end"
      end
      
      klass_assocs.each_key do |k|
        @associations[k] = ActiveCouch::HasManyAssociation.new(klass_assocs[k].name, :class => klass_assocs[k].klass)
        self.instance_eval "def #{k}; associations[:#{k}].container; end"
        # If you have has_many :people, this will add a method called add_person to the object instantiated
        # from the class
        self.instance_eval "def add_#{Inflector.singularize(k)}(val); associations[:#{k}].push(val); end"
      end
    end

    class << self # Class methods
      def has(name, options = {})
        unless name.is_a?(String) || name.is_a?(Symbol)
          raise ArgumentError, "#{name} is neither a String nor a Symbol"
        end
        @attributes[name] = Attribute.new(options)  
      end

      def has_many(name, options = {})
        unless name.is_a?(String) || name.is_a?(Symbol)
          raise ArgumentError, "#{name} is neither a String nor a Symbol"
        end
        @associations[name] = HasManyAssociation.new(name, options)
      end
      
      # All classes inheriting from ActiveCouch::Base will have
      # a class instance variable called @attributes
      def inherited(subklass)
        subklass.instance_variable_set "@attributes", {}
        subklass.instance_variable_set "@associations", {}
        
        subklass.instance_eval "def attributes; @attributes; end"
        subklass.instance_eval "def associations; @associations; end"
      end      
    end # End class methods
  end # End class Base
end # End module ActiveCouch